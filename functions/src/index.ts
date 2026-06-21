import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { fetchAlAdhanQibla } from "./aladhan_service";
import { getPrayerTimes, getPrayerTimesForDateKey } from "./prayer_times_service";
import {
  dateKey,
  DISPLAY_NAMES,
  isFastingHours,
  nextPrayerDate,
  PRAYER_NAMES,
  PrayerName,
  prayerDate,
  prayerWindowClosed,
} from "./prayer_types";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const SKIP_STATUSES = new Set(["traveling", "excused", "in_exam"]);

function gregorianToHijri(date: Date): { month: number; day: number } {
  const jd = Math.floor(date.getTime() / 86400000 + 2440587.5);
  const l = jd - 1948440 + 10632;
  const n = Math.floor((l - 1) / 10631);
  const l2 = l - 10631 * n + 354;
  const j =
    Math.floor((10985 - l2) / 5316) * Math.floor((50 * l2) / 17719) +
    Math.floor(l2 / 5670) * Math.floor((43 * l2) / 15238);
  const l3 =
    l2 -
    Math.floor((30 - j) / 15) * Math.floor((17719 * j) / 50) -
    Math.floor(j / 16) * Math.floor((15238 * j) / 43) +
    29;
  const month = Math.floor((24 * l3) / 709);
  const day = l3 - Math.floor((709 * month) / 24);
  return { month, day };
}

function isRamadanActive(settings: FirebaseFirestore.DocumentData, now = new Date()): boolean {
  const override = settings.ramadanModeOverride as string | undefined;
  if (override === "on") return true;
  if (override === "off") return false;
  return gregorianToHijri(now).month === 9;
}

async function getEffectiveUserStatus(uid: string): Promise<string> {
  const statusSnap = await db.doc(`users/${uid}/status`).get();
  const data = statusSnap.data();
  if (!data) return "active";

  const current = (data.current as string) ?? "active";
  const expiresAt = data.expiresAt as admin.firestore.Timestamp | undefined;
  if (expiresAt && expiresAt.toDate() < new Date()) {
    return "active";
  }
  return current;
}

async function getFcmToken(uid: string): Promise<string | null> {
  const tokenSnap = await db.doc(`users/${uid}/fcmToken`).get();
  const token = tokenSnap.data()?.token;
  return typeof token === "string" ? token : null;
}

async function getDisplayName(uid: string): Promise<string> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const data = userSnap.data();
  return (data?.displayName as string) || (data?.email as string) || "A circle member";
}

async function assertCircleMember(circleId: string, uid: string) {
  const circleSnap = await db.doc(`circles/${circleId}`).get();
  const members = (circleSnap.data()?.members as string[]) ?? [];
  if (!members.includes(uid)) {
    throw new HttpsError("permission-denied", "Not a member of this circle.");
  }
  return members;
}

export const checkMissedPrayers = onSchedule("every 30 minutes", async () => {
  const now = new Date();
  const today = dateKey(now);

  const circlesSnap = await db.collection("circles").get();
  const memberToCircles = new Map<string, Set<string>>();

  circlesSnap.docs.forEach((doc) => {
    const members = doc.data().members as string[] | undefined;
    if (!Array.isArray(members)) return;
    members.forEach((uid) => {
      if (!memberToCircles.has(uid)) memberToCircles.set(uid, new Set());
      memberToCircles.get(uid)!.add(doc.id);
    });
  });

  for (const [uid, circleIds] of memberToCircles.entries()) {
    const settingsSnap = await db.doc(`users/${uid}/settings/preferences`).get();
    const settings = settingsSnap.data();
    if (!settings) continue;

    const userStatus = await getEffectiveUserStatus(uid);
    if (userStatus !== "active" && SKIP_STATUSES.has(userStatus)) continue;

    const prayerTimes = await getPrayerTimes(db, uid, settings, now);
    if (!prayerTimes) continue;

    for (const prayer of PRAYER_NAMES) {
      const prayerAt = prayerDate(prayerTimes, prayer);
      const nextAt = nextPrayerDate(prayerTimes, prayer);
      if (!prayerWindowClosed(now, prayerAt, nextAt)) continue;

      const entryRef = db.doc(`users/${uid}/prayer_logs/${today}/prayers/${prayer}`);
      const entrySnap = await entryRef.get();
      const entry = entrySnap.data();

      if (entry?.checkedOff === true || entry?.status === "completed") continue;
      if (entry?.status === "excused") continue;

      if (!entrySnap.exists || entry?.status !== "missed") {
        await entryRef.set(
          {
            checkedOff: false,
            status: "missed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      const displayName = await getDisplayName(uid);
      const prayerLabel = DISPLAY_NAMES[prayer];

      for (const circleId of circleIds) {
        const circleSnap = await db.doc(`circles/${circleId}`).get();
        const members = (circleSnap.data()?.members as string[]) ?? [];

        const muteCircleAlerts =
          isRamadanActive(settings, now) && isFastingHours(now, prayerTimes);

        for (const memberUid of members) {
          if (memberUid === uid) continue;
          if (muteCircleAlerts) continue;

          const token = await getFcmToken(memberUid);
          if (!token) continue;

          await messaging.send({
            token,
            notification: {
              title: `${displayName} hasn't checked off ${prayerLabel} yet`,
              body: "Tap to send them a reminder 🤲",
            },
            data: {
              type: "missed_prayer",
              targetUid: uid,
              prayerName: prayer,
              circleId,
            },
            android: {
              notification: {
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
                actions: [
                  { title: "Send Reminder", clickAction: "SEND_REMINDER" },
                  { title: "Send Dua", clickAction: "SEND_DUA" },
                ],
              } as admin.messaging.AndroidNotification,
            },
          });
        }
      }
    }
  }
});

export const sendPrayerReminder = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const targetUid = request.data?.targetUid as string | undefined;
  const prayerName = request.data?.prayerName as string | undefined;
  const circleId = request.data?.circleId as string | undefined;

  if (!targetUid || !prayerName || !circleId) {
    throw new HttpsError("invalid-argument", "Missing reminder payload.");
  }

  await assertCircleMember(circleId, request.auth.uid);
  await assertCircleMember(circleId, targetUid);

  const senderName = await getDisplayName(request.auth.uid);
  const token = await getFcmToken(targetUid);
  if (!token) {
    throw new HttpsError("failed-precondition", "Target user has no FCM token.");
  }

  const label = DISPLAY_NAMES[prayerName as PrayerName] ?? prayerName;

  await messaging.send({
    token,
    notification: {
      title: `${senderName} sent you a reminder`,
      body: `Don't forget ${label} 🤲`,
    },
    data: {
      type: "prayer_reminder",
      senderUid: request.auth.uid,
      prayerName,
      circleId,
    },
  });

  return { ok: true };
});

export const sendDua = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const circleId = request.data?.circleId as string | undefined;
  const requestId = request.data?.requestId as string | undefined;
  if (!circleId || !requestId) {
    throw new HttpsError("invalid-argument", "Missing Dua payload.");
  }

  await assertCircleMember(circleId, request.auth.uid);

  const duaRef = db.doc(`circles/${circleId}/dua_requests/${requestId}`);
  const duaSnap = await duaRef.get();
  if (!duaSnap.exists) {
    throw new HttpsError("not-found", "Dua request not found.");
  }

  const authorUid = duaSnap.data()?.authorUid as string;
  if (authorUid === request.auth.uid) {
    throw new HttpsError("failed-precondition", "Cannot make Dua on your own request.");
  }

  await duaRef.update({
    duaSenders: admin.firestore.FieldValue.arrayUnion([request.auth.uid]),
  });

  const senderName = await getDisplayName(request.auth.uid);
  const authorToken = await getFcmToken(authorUid);
  if (authorToken) {
    await messaging.send({
      token: authorToken,
      notification: {
        title: `${senderName} is making Dua for you`,
        body: `${senderName} is making Dua for you to find ease 🤲`,
      },
      data: {
        type: "dua_received",
        circleId,
        requestId,
        senderUid: request.auth.uid,
      },
    });
  }

  return { ok: true };
});

export const sendDuaForMissedPrayer = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const circleId = request.data?.circleId as string | undefined;
  const targetUid = request.data?.targetUid as string | undefined;
  const prayerName = request.data?.prayerName as string | undefined;

  if (!circleId || !targetUid || !prayerName) {
    throw new HttpsError("invalid-argument", "Missing missed-prayer Dua payload.");
  }

  await assertCircleMember(circleId, request.auth.uid);
  await assertCircleMember(circleId, targetUid);

  if (targetUid === request.auth.uid) {
    throw new HttpsError("failed-precondition", "Cannot send Dua to yourself.");
  }

  const senderName = await getDisplayName(request.auth.uid);
  const targetName = await getDisplayName(targetUid);
  const prayerLabel = DISPLAY_NAMES[prayerName as PrayerName] ?? prayerName;

  const duaRef = await db.collection(`circles/${circleId}/dua_requests`).add({
    authorUid: request.auth.uid,
    authorName: senderName,
    message: `Making Dua for ${targetName}'s ${prayerLabel}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    duaSenders: [request.auth.uid],
    source: "missed_prayer",
    targetUid,
    prayerName,
  });

  const targetToken = await getFcmToken(targetUid);
  if (targetToken) {
    await messaging.send({
      token: targetToken,
      notification: {
        title: `${senderName} is making Dua for you`,
        body: `${senderName} is making Dua for you to find ease 🤲`,
      },
      data: {
        type: "dua_received",
        circleId,
        requestId: duaRef.id,
        senderUid: request.auth.uid,
      },
    });
  }

  return { ok: true, requestId: duaRef.id };
});

// ---------------------------------------------------------------------------
// Habit Engine — streaks & badges (runs hourly; processes users at ~23:59 local)
// ---------------------------------------------------------------------------

function isValidIanaTimezone(timeZone: string): boolean {
  try {
    Intl.DateTimeFormat(undefined, { timeZone });
    return true;
  } catch {
    return false;
  }
}

function localDateKeyFromSettings(
  now: Date,
  settings: FirebaseFirestore.DocumentData,
): string {
  const tz = settings.timezone as string | undefined;
  if (tz && isValidIanaTimezone(tz)) {
    return localDateKey(now, tz);
  }

  const offsetMinutes = settings.timezoneOffsetMinutes as number | undefined;
  if (offsetMinutes != null) {
    const local = new Date(now.getTime() + offsetMinutes * 60 * 1000);
    return local.toISOString().slice(0, 10);
  }

  return dateKey(now);
}

function localDateKey(now: Date, timeZone: string): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now);
}

function isEndOfLocalDay(now: Date, timeZone: string): boolean {
  const hour = Number(
    new Intl.DateTimeFormat("en-US", { timeZone, hour: "numeric", hour12: false }).format(now),
  );
  const minute = Number(
    new Intl.DateTimeFormat("en-US", { timeZone, minute: "numeric" }).format(now),
  );
  return hour === 23 && minute >= 45;
}

function isEndOfLocalDayFromSettings(
  now: Date,
  settings: FirebaseFirestore.DocumentData,
): boolean {
  const tz = settings.timezone as string | undefined;
  if (tz && isValidIanaTimezone(tz)) {
    return isEndOfLocalDay(now, tz);
  }

  const offsetMinutes = settings.timezoneOffsetMinutes as number | undefined;
  if (offsetMinutes != null) {
    const local = new Date(now.getTime() + offsetMinutes * 60 * 1000);
    return local.getUTCHours() === 23 && local.getUTCMinutes() >= 45;
  }

  return now.getUTCHours() === 23 && now.getUTCMinutes() >= 45;
}

async function allPrayersCompleted(uid: string, dateKey: string): Promise<boolean> {
  for (const prayer of PRAYER_NAMES) {
    const snap = await db.doc(`users/${uid}/prayer_logs/${dateKey}/prayers/${prayer}`).get();
    const data = snap.data();
    if (!data || data.status !== "completed" || data.checkedOff !== true) {
      return false;
    }
  }
  return true;
}

function previousDateKey(dateKey: string): string {
  const [y, m, d] = dateKey.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return dt.toISOString().slice(0, 10);
}

async function updatePersonalStreak(uid: string, todayKey: string) {
  const completed = await allPrayersCompleted(uid, todayKey);
  const streakRef = db.doc(`users/${uid}/streak`);
  const streakSnap = await streakRef.get();
  const prev = streakSnap.data() ?? {};

  let current = (prev.currentStreak as number) ?? 0;
  let longest = (prev.longestStreak as number) ?? 0;
  const lastCompleted = prev.lastCompletedDate as string | undefined;

  if (completed) {
    if (lastCompleted === previousDateKey(todayKey)) {
      current += 1;
    } else if (lastCompleted !== todayKey) {
      current = 1;
    }
    longest = Math.max(longest, current);
    await streakRef.set(
      {
        currentStreak: current,
        longestStreak: longest,
        lastCompletedDate: todayKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } else {
    await streakRef.set(
      {
        currentStreak: 0,
        longestStreak: longest,
        lastCompletedDate: lastCompleted ?? null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

async function updateCircleStreak(circleId: string, todayKey: string) {
  const circleSnap = await db.doc(`circles/${circleId}`).get();
  const members = (circleSnap.data()?.members as string[]) ?? [];
  if (members.length === 0) return;

  let allComplete = true;
  for (const uid of members) {
    if (!(await allPrayersCompleted(uid, todayKey))) {
      allComplete = false;
      break;
    }
  }

  const streakRef = db.doc(`circles/${circleId}/streak`);
  const prevSnap = await streakRef.get();
  const prev = prevSnap.data() ?? {};
  let current = (prev.currentStreak as number) ?? 0;
  let longest = (prev.longestStreak as number) ?? 0;
  const lastDate = prev.lastFullyCompletedDate as string | undefined;

  if (allComplete) {
    if (lastDate === previousDateKey(todayKey)) current += 1;
    else if (lastDate !== todayKey) current = 1;
    longest = Math.max(longest, current);
    await streakRef.set(
      {
        currentStreak: current,
        longestStreak: longest,
        lastFullyCompletedDate: todayKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (current >= 7) {
      for (const uid of members) {
        await unlockBadge(uid, "circle_champion");
      }
    }
  } else {
    await streakRef.set(
      {
        currentStreak: 0,
        longestStreak: longest,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

async function unlockBadge(uid: string, badgeId: string) {
  const ref = db.doc(`users/${uid}/badges/${badgeId}`);
  const snap = await ref.get();
  if (snap.exists) return;

  await ref.set({ unlockedAt: admin.firestore.FieldValue.serverTimestamp() });

  const token = await getFcmToken(uid);
  if (!token) return;

  await messaging.send({
    token,
    notification: {
      title: "Badge unlocked! 🏅",
      body: `You earned the ${badgeId.replace(/_/g, " ")} badge`,
    },
    data: { type: "badge_unlocked", badgeId },
  });
}

async function prayerOnTime(
  uid: string,
  dateKey: string,
  prayer: PrayerName,
  settings: FirebaseFirestore.DocumentData,
): Promise<boolean> {
  const snap = await db.doc(`users/${uid}/prayer_logs/${dateKey}/prayers/${prayer}`).get();
  const data = snap.data();
  if (!data || data.status !== "completed" || !data.checkedAt) return false;

  const times = await getPrayerTimesForDateKey(db, uid, settings, dateKey);
  if (!times) return false;

  const prayerAt = prayerDate(times, prayer);
  const checkedAt = (data.checkedAt as admin.firestore.Timestamp).toDate();
  const diffMin = Math.abs((checkedAt.getTime() - prayerAt.getTime()) / 60000);
  return diffMin <= 15;
}

async function consecutiveOnTimeCount(
  uid: string,
  prayer: PrayerName,
  days: number,
  settings: FirebaseFirestore.DocumentData,
  endDateKey: string,
): Promise<number> {
  let count = 0;
  let key = endDateKey;
  for (let i = 0; i < days; i++) {
    if (await prayerOnTime(uid, key, prayer, settings)) {
      count++;
    } else {
      break;
    }
    key = previousDateKey(key);
  }
  return count;
}

async function checkBadges(uid: string, todayKey: string, settings: FirebaseFirestore.DocumentData) {
  const fajr7 = await consecutiveOnTimeCount(uid, "fajr", 7, settings, todayKey);
  if (fajr7 >= 7) await unlockBadge(uid, "dawn_warrior");

  const fajr30 = await consecutiveOnTimeCount(uid, "fajr", 30, settings, todayKey);
  if (fajr30 >= 30) await unlockBadge(uid, "dawn_warrior_30");

  let perfectDays = 0;
  let key = todayKey;
  for (let i = 0; i < 7; i++) {
    if (await allPrayersCompleted(uid, key)) perfectDays++;
    else break;
    key = previousDateKey(key);
  }
  if (perfectDays >= 7) await unlockBadge(uid, "perfect_week");

  let earlyBird = 0;
  key = todayKey;
  for (let i = 0; i < 10; i++) {
    if (await prayerOnTime(uid, key, "fajr", settings)) earlyBird++;
    else break;
    key = previousDateKey(key);
  }
  if (earlyBird >= 10) await unlockBadge(uid, "early_bird");

  let nightOwl = 0;
  key = todayKey;
  for (let i = 0; i < 10; i++) {
    if (await prayerOnTime(uid, key, "isha", settings)) nightOwl++;
    else break;
    key = previousDateKey(key);
  }
  if (nightOwl >= 10) await unlockBadge(uid, "night_owl");
}

/** Callable sync: fetches AlAdhan timings + Qibla and caches them server-side. */
export const syncIslamicData = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const uid = request.auth.uid;
  const settingsSnap = await db.doc(`users/${uid}/settings/preferences`).get();
  const settings = settingsSnap.data();
  if (!settings) {
    throw new HttpsError("failed-precondition", "User settings not found.");
  }

  const lat = settings.latitude as number | undefined;
  const lng = settings.longitude as number | undefined;
  if (lat == null || lng == null) {
    throw new HttpsError("failed-precondition", "Location not configured.");
  }

  const today = dateKey(new Date());
  const times = await getPrayerTimes(db, uid, settings, new Date());
  const qibla = await fetchAlAdhanQibla(lat, lng);

  if (times?.hijriDate) {
    await db.doc(`users/${uid}/islamic_data/hijri`).set(
      {
        date: today,
        hijriDate: times.hijriDate,
        timezone: times.timezone ?? null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  if (qibla != null) {
    await db.doc(`users/${uid}/islamic_data/qibla`).set(
      {
        direction: qibla,
        latitude: lat,
        longitude: lng,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  return {
    ok: true,
    source: times?.source ?? null,
    hijriDate: times?.hijriDate ?? null,
    qiblaDirection: qibla,
  };
});

export const calculateStreaksAndBadges = onSchedule("every 60 minutes", async () => {
  const now = new Date();
  const usersSnap = await db.collection("users").get();

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    const settingsSnap = await db.doc(`users/${uid}/settings/preferences`).get();
    const settings = settingsSnap.data();
    if (!settings) continue;

    if (!isEndOfLocalDayFromSettings(now, settings)) continue;

    const todayKey = localDateKeyFromSettings(now, settings);
    await updatePersonalStreak(uid, todayKey);
    await checkBadges(uid, todayKey, settings);
  }

  const circlesSnap = await db.collection("circles").get();
  for (const circleDoc of circlesSnap.docs) {
    const members = (circleDoc.data().members as string[]) ?? [];
    if (members.length === 0) continue;

    const firstSettings = await db.doc(`users/${members[0]}/settings/preferences`).get();
    const settings = firstSettings.data() ?? {};
    if (!isEndOfLocalDayFromSettings(now, settings)) continue;

    const todayKey = localDateKeyFromSettings(now, settings);
    await updateCircleStreak(circleDoc.id, todayKey);
  }
});
