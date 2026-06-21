import * as admin from "firebase-admin";

import { fetchAlAdhanTimings } from "./aladhan_service";
import { calculateLocalPrayerTimes, localPrayerTimesForDateKey } from "./local_prayer_calculator";
import { dateKey, PrayerTimesResult } from "./prayer_types";

function cacheDocPath(uid: string, dateKeyValue: string): string {
  return `users/${uid}/islamic_data/prayer_cache/${dateKeyValue}`;
}

function resultFromCache(data: FirebaseFirestore.DocumentData): PrayerTimesResult {
  return {
    fajr: new Date(data.fajr as string),
    dhuhr: new Date(data.dhuhr as string),
    asr: new Date(data.asr as string),
    maghrib: new Date(data.maghrib as string),
    isha: new Date(data.isha as string),
    source: (data.source as "aladhan" | "local") ?? "aladhan",
    timezone: data.timezone as string | undefined,
    hijriDate: data.hijriDate as string | undefined,
  };
}

async function readCache(
  db: FirebaseFirestore.Firestore,
  uid: string,
  dateKeyValue: string,
): Promise<PrayerTimesResult | null> {
  const snap = await db.doc(cacheDocPath(uid, dateKeyValue)).get();
  if (!snap.exists) return null;
  const data = snap.data();
  if (!data?.fajr || !data?.isha) return null;
  return resultFromCache(data);
}

async function writeCache(
  db: FirebaseFirestore.Firestore,
  uid: string,
  dateKeyValue: string,
  times: PrayerTimesResult,
): Promise<void> {
  await db.doc(cacheDocPath(uid, dateKeyValue)).set(
    {
      fajr: times.fajr.toISOString(),
      dhuhr: times.dhuhr.toISOString(),
      asr: times.asr.toISOString(),
      maghrib: times.maghrib.toISOString(),
      isha: times.isha.toISOString(),
      source: times.source,
      timezone: times.timezone ?? null,
      hijriDate: times.hijriDate ?? null,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/**
 * Resolves prayer times for server-side verification.
 * Priority: Firestore cache → AlAdhan REST API → local adhan npm fallback.
 */
export async function getPrayerTimes(
  db: FirebaseFirestore.Firestore,
  uid: string,
  settings: FirebaseFirestore.DocumentData,
  date = new Date(),
): Promise<PrayerTimesResult | null> {
  const lat = settings.latitude as number | undefined;
  const lng = settings.longitude as number | undefined;
  if (lat == null || lng == null) return null;

  const key = dateKey(date);

  const cached = await readCache(db, uid, key);
  if (cached) return cached;

  const aladhan = await fetchAlAdhanTimings(
    lat,
    lng,
    settings.calculationMethod as string | undefined,
    settings.madhab as string | undefined,
    date,
  );

  if (aladhan) {
    await writeCache(db, uid, key, aladhan);
    return aladhan;
  }

  const local = calculateLocalPrayerTimes(settings, date);
  if (local) {
    await writeCache(db, uid, key, local);
  }
  return local;
}

export async function getPrayerTimesForDateKey(
  db: FirebaseFirestore.Firestore,
  uid: string,
  settings: FirebaseFirestore.DocumentData,
  dateKeyValue: string,
): Promise<PrayerTimesResult | null> {
  const cached = await readCache(db, uid, dateKeyValue);
  if (cached) return cached;

  const lat = settings.latitude as number | undefined;
  const lng = settings.longitude as number | undefined;
  if (lat == null || lng == null) return null;

  const [y, m, d] = dateKeyValue.split("-").map(Number);
  const date = new Date(y, m - 1, d, 12, 0, 0);

  const aladhan = await fetchAlAdhanTimings(
    lat,
    lng,
    settings.calculationMethod as string | undefined,
    settings.madhab as string | undefined,
    date,
  );

  if (aladhan) {
    await writeCache(db, uid, dateKeyValue, aladhan);
    return aladhan;
  }

  const local = localPrayerTimesForDateKey(settings, dateKeyValue);
  if (local) {
    await writeCache(db, uid, dateKeyValue, local);
  }
  return local;
}
