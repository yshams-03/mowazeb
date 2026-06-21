import { CalculationMethod, Coordinates, Madhab, PrayerTimes } from "adhan";

import { dateKey, PrayerTimesResult } from "./prayer_types";

const HIGH_LATITUDE_MAX_DAYS = 7;

function parseMethod(value?: string) {
  switch (value) {
    case "ISNA":
      return CalculationMethod.NorthAmerica();
    case "Egyptian":
      return CalculationMethod.Egyptian();
    case "Umm al-Qura":
      return CalculationMethod.UmmAlQura();
    case "Karachi":
      return CalculationMethod.Karachi();
    default:
      return CalculationMethod.MuslimWorldLeague();
  }
}

function isValidPrayerTimes(prayerTimes: PrayerTimes): boolean {
  return [
    prayerTimes.fajr,
    prayerTimes.dhuhr,
    prayerTimes.asr,
    prayerTimes.maghrib,
    prayerTimes.isha,
  ].every((time) => !Number.isNaN(time.getTime()));
}

function prayerTimesForDate(
  lat: number,
  lng: number,
  settings: FirebaseFirestore.DocumentData,
  date: Date,
): PrayerTimes {
  const params = parseMethod(settings.calculationMethod as string | undefined);
  params.madhab = settings.madhab === "Hanafi" ? Madhab.Hanafi : Madhab.Shafi;
  return new PrayerTimes(new Coordinates(lat, lng), date, params);
}

/** Offline fallback using the adhan npm library (same formulas as the Flutter client). */
export function calculateLocalPrayerTimes(
  settings: FirebaseFirestore.DocumentData,
  date = new Date(),
): PrayerTimesResult | null {
  const lat = settings.latitude as number | undefined;
  const lng = settings.longitude as number | undefined;
  if (lat == null || lng == null) return null;

  for (let offset = 0; offset <= HIGH_LATITUDE_MAX_DAYS; offset++) {
    const target = new Date(date);
    target.setDate(target.getDate() - offset);

    const prayerTimes = prayerTimesForDate(lat, lng, settings, target);
    if (!isValidPrayerTimes(prayerTimes)) continue;

    return {
      fajr: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      source: "local",
      timezone: (settings.timezone as string | undefined) ?? undefined,
    };
  }

  return null;
}

export function localPrayerTimesForDateKey(
  settings: FirebaseFirestore.DocumentData,
  dateKeyValue: string,
): PrayerTimesResult | null {
  const [y, m, d] = dateKeyValue.split("-").map(Number);
  return calculateLocalPrayerTimes(settings, new Date(y, m - 1, d, 12, 0, 0));
}

export function todayDateKey(): string {
  return dateKey(new Date());
}
