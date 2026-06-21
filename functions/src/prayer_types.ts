export const PRAYER_NAMES = ["fajr", "dhuhr", "asr", "maghrib", "isha"] as const;
export type PrayerName = (typeof PRAYER_NAMES)[number];

export const DISPLAY_NAMES: Record<PrayerName, string> = {
  fajr: "Fajr",
  dhuhr: "Dhuhr",
  asr: "Asr",
  maghrib: "Maghrib",
  isha: "Isha",
};

/** Normalized prayer schedule used by missed-prayer and badge logic. */
export interface PrayerTimesResult {
  fajr: Date;
  dhuhr: Date;
  asr: Date;
  maghrib: Date;
  isha: Date;
  source: "aladhan" | "local";
  timezone?: string;
  hijriDate?: string;
}

export function dateKey(date = new Date()): string {
  const y = date.getFullYear();
  const m = `${date.getMonth() + 1}`.padStart(2, "0");
  const d = `${date.getDate()}`.padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function alAdhanUnixTimestamp(date = new Date()): number {
  const local = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  return Math.floor(local.getTime() / 1000);
}

export function prayerDate(prayerTimes: PrayerTimesResult, prayer: PrayerName): Date {
  switch (prayer) {
    case "fajr":
      return prayerTimes.fajr;
    case "dhuhr":
      return prayerTimes.dhuhr;
    case "asr":
      return prayerTimes.asr;
    case "maghrib":
      return prayerTimes.maghrib;
    case "isha":
      return prayerTimes.isha;
  }
}

export function nextPrayerDate(
  prayerTimes: PrayerTimesResult,
  prayer: PrayerName,
): Date | null {
  const order: PrayerName[] = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
  const index = order.indexOf(prayer);
  if (index < 0 || index >= order.length - 1) return null;
  return prayerDate(prayerTimes, order[index + 1]);
}

export function prayerWindowClosed(
  now: Date,
  prayerAt: Date,
  nextPrayerAt: Date | null,
  graceMinutes = 10,
): boolean {
  const graceMs = graceMinutes * 60 * 1000;
  const closedAfter = new Date(prayerAt.getTime() + graceMs);
  if (now < closedAfter) return false;
  if (nextPrayerAt && now >= nextPrayerAt) return true;
  return now >= closedAfter;
}

export function isFastingHours(now: Date, prayerTimes: PrayerTimesResult): boolean {
  return now >= prayerTimes.fajr && now < prayerTimes.maghrib;
}
