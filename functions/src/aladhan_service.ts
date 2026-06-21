import {
  alAdhanUnixTimestamp,
  dateKey,
  PrayerTimesResult,
} from "./prayer_types";

const BASE_URL = "https://api.aladhan.com/v1";

/** Maps app calculation method labels to AlAdhan method IDs. */
export const ALADHAN_METHOD_IDS: Record<string, number> = {
  MWL: 3,
  ISNA: 2,
  Egyptian: 5,
  "Umm al-Qura": 4,
  Karachi: 1,
};

interface AlAdhanTimingsResponse {
  code: number;
  data?: {
    timings: Record<string, string>;
    date?: {
      hijri?: {
        date?: string;
      };
    };
    meta?: {
      timezone?: string;
    };
  };
}

interface AlAdhanQiblaResponse {
  code: number;
  data?: {
    direction?: number;
  };
}

/** Converts a local wall-clock time in an IANA timezone to a UTC Date. */
export function localTimeToUtc(
  dateKeyValue: string,
  timeStr: string,
  timeZone: string,
): Date {
  const [year, month, day] = dateKeyValue.split("-").map(Number);
  const clean = timeStr.replace(/\s*\([^)]*\)/, "").trim();
  const [hour, minute] = clean.split(":").map(Number);

  const utcGuess = Date.UTC(year, month - 1, day, hour, minute, 0);
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour12: false,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });

  const parts = Object.fromEntries(
    formatter.formatToParts(new Date(utcGuess)).map((part) => [part.type, part.value]),
  );

  const asUtc = Date.UTC(
    Number(parts.year),
    Number(parts.month) - 1,
    Number(parts.day),
    Number(parts.hour),
    Number(parts.minute),
    Number(parts.second),
  );

  const offset = asUtc - utcGuess;
  return new Date(utcGuess - offset);
}

export function mapCalculationMethod(method?: string): number {
  if (!method) return ALADHAN_METHOD_IDS.MWL;
  return ALADHAN_METHOD_IDS[method] ?? ALADHAN_METHOD_IDS.MWL;
}

export function mapMadhabSchool(madhab?: string): number {
  return madhab === "Hanafi" ? 1 : 0;
}

export async function fetchAlAdhanTimings(
  latitude: number,
  longitude: number,
  calculationMethod: string | undefined,
  madhab: string | undefined,
  date = new Date(),
): Promise<PrayerTimesResult | null> {
  const key = dateKey(date);
  const timestamp = alAdhanUnixTimestamp(date);
  const methodId = mapCalculationMethod(calculationMethod);
  const school = mapMadhabSchool(madhab);

  const url =
    `${BASE_URL}/timings/${timestamp}` +
    `?latitude=${latitude}&longitude=${longitude}` +
    `&method=${methodId}&school=${school}`;

  try {
    const response = await fetch(url);
    if (!response.ok) return null;

    const json = (await response.json()) as AlAdhanTimingsResponse;
    if (json.code !== 200 || !json.data?.timings) return null;

    const timezone = json.data.meta?.timezone ?? "UTC";
    const timings = json.data.timings;

    return {
      fajr: localTimeToUtc(key, timings.Fajr, timezone),
      dhuhr: localTimeToUtc(key, timings.Dhuhr, timezone),
      asr: localTimeToUtc(key, timings.Asr, timezone),
      maghrib: localTimeToUtc(key, timings.Maghrib, timezone),
      isha: localTimeToUtc(key, timings.Isha, timezone),
      source: "aladhan",
      timezone,
      hijriDate: json.data.date?.hijri?.date,
    };
  } catch {
    return null;
  }
}

export async function fetchAlAdhanQibla(
  latitude: number,
  longitude: number,
): Promise<number | null> {
  const url = `${BASE_URL}/qibla/${latitude}/${longitude}`;

  try {
    const response = await fetch(url);
    if (!response.ok) return null;

    const json = (await response.json()) as AlAdhanQiblaResponse;
    if (json.code !== 200 || json.data?.direction == null) return null;
    return json.data.direction;
  } catch {
    return null;
  }
}
