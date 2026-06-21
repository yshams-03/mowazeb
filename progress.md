# UmmahPulse (mowazeb / مواظب) — Project Progress

**Last updated:** June 21, 2026  
**Version:** 1.0.0+1  
**Phase:** All 7 phases implemented — polish, QA, and release prep

---

## Overview

UmmahPulse is a smart lifestyle and habit app for busy Muslims. The full feature set across all seven development phases is implemented: prayer times, Smart Day Planner, saved places, Smart Commute Advisor, accountability circles, analytics/badges, Qibla, Ramadan mode, bilingual UI (EN/AR), and settings. Cloud Functions back missed-prayer checks, badge unlocks, and AlAdhan prayer-time sync.

---

## Completed

### Project setup
- [x] Flutter project scaffolded (`ummah_pulse`, org `com.ummahpulse`)
- [x] Platform folders generated (Android, iOS, Web, Windows, macOS, Linux)
- [x] Dependencies installed and resolving cleanly
- [x] `flutter analyze` — 0 errors, 0 warnings (info-level `prefer_const_*` hints only)
- [x] Android location + notification permissions configured
- [x] iOS location usage descriptions configured
- [x] Firestore security rules (`firestore.rules`) — users, circles, dua_requests, circle_lookup, islamic_data
- [x] Setup script (`setup.ps1`) and README
- [x] Android build — `compileSdk 36`; release APK builds successfully (68.4 MB)
- [x] `.env` for secrets (`ORS_API_KEY`); `.env` in `.gitignore`

### Core infrastructure
- [x] Riverpod state management (`ProviderScope` in `main.dart`)
- [x] GoRouter navigation with auth/onboarding guards
- [x] Light + dark Material 3 theme (green/teal palette) + system theme follow
- [x] App constants (routes, Firestore paths, calculation methods)
- [x] Splash/loading screen while auth + settings initialize
- [x] Local notifications service (wudu nudge, Ramadan suhoor/iftar reminders)
- [x] Home screen widget (`home_widget` package) with test-mode bypass
- [x] Arabic localization + RTL layout support
- [x] Arabic numerals toggle (`AppFormat`)

### Authentication
- [x] Email/password sign-in and registration
- [x] Google Sign-In (debug SHA-1 registered, `serverClientId` configured)
- [x] Loading and error states with user-friendly messages
- [x] Firestore user document creation on first sign-in
- [x] Auth state stream drives routing
- [x] Sign out + delete account (double confirmation in settings)

### Onboarding
- [x] Step 1 — Location permission request with animated pin UI
- [x] Step 2 — Calculation method selection (MWL, ISNA, Egyptian, Umm al-Qura, Karachi)
- [x] Step 3 — Madhab selection for Asr (Standard / Hanafi)
- [x] Preferences saved to `users/{uid}/settings/preferences`

### Prayer times (core loop)
- [x] **Local calculation** via `adhan` — instant, offline UI
- [x] **SharedPreferences cache** for cold-start prayer times (`PrayerCacheService`)
- [x] **Once-per-day AlAdhan sync** (`AlAdhanSyncService`) for server-side verification
- [x] **High-latitude fallback** — nearest calculable day for polar regions (e.g. Tromsø midnight sun)
- [x] User-configurable calculation method and madhab
- [x] Today's 5 prayers via `prayerProvider` (cache → local calc → background sync)
- [x] Next prayer detection with passed/upcoming states
- [x] Live countdown stream (`timeUntilNextPrayerProvider`)
- [x] Midnight recalculation timer
- [x] Daily prayer log + check-off (gated until prayer time passes)
- [x] `NextPrayerCard` + `PrayerTimesPanel` (Gregorian + Hijri, location label, countdown)
- [x] GPS watch — recalculates when user moves 500 m+
- [x] Home screen pull-to-refresh

### My Places (saved locations)
- [x] **Places** tab in bottom nav
- [x] Save Home, Work, and custom places (name + address + coordinates)
- [x] Auto-seed **Home** from onboarding GPS on first load
- [x] Place search via Nominatim + abbreviation expansion (`aast` → Arab Academy)
- [x] Map picker screen for pin-drop selection
- [x] Firestore persistence at `users/{uid}/saved_locations/{id}`

### Smart Day Planner (Pillar A)
- [x] Routine schedule blocks (title, saved location, start/end time, days, color)
- [x] Weekly calendar view (Mon–Sun) with colored blocks
- [x] Add Block bottom sheet — pick from saved places
- [x] `PlannerEngine` — tags prayers as at home / at location / transition (15 min window)
- [x] Wudu nudge notifications (10 min before transition prayers)
- [x] Firestore persistence at `users/{uid}/routine_blocks/{id}`

### Smart Commute Advisor (Pillar B)
- [x] **Commute** tab in bottom nav
- [x] "Can I Make It?" GREEN/RED verdict via OpenRouteService (ORS)
- [x] Drive-time vs next-prayer buffer calculation
- [x] Mosque finder along route (top 3, Google Maps deep link)
- [x] Home pre-selected as destination when saved
- [x] Loading shimmer, error state with retry
- [x] `ORS_API_KEY` from `.env` (not hardcoded)

### Peer Accountability Circles (Pillar C)
- [x] **Community** tab — circles list, create, join via 6-char invite code
- [x] `circle_lookup/{code}` collection for invite-code queries (Firestore rules fix)
- [x] Circle detail — live prayer feed, member rows, group streak
- [x] Prayer check-off syncs to circle feed in real time
- [x] Dua Board — post requests, "Make Dua" button, sender tracking
- [x] Status toggle — Traveling / Excused / In Exam (suppresses missed alerts)
- [x] FCM service wired for push notification data payloads
- [x] Cloud Functions: `checkMissedPrayers`, `sendDua`, `sendDuaForMissedPrayer`

### Privacy & Support (Pillar D)
- [x] Excuse/status toggle with public labels (no private reason exposed)
- [x] Group Dua requests bulletin per circle
- [x] Traveling member — no red X for missed prayers in feed

### Habit Engine & Analytics (Pillar E)
- [x] **Analytics** tab — private lock banner
- [x] Personal + group streak widgets
- [x] 30-day completion bar chart (`fl_chart`)
- [x] Per-prayer timing chart
- [x] Schedule correlation insights (`AnalyticsEngine`)
- [x] Weekly heatmap grid (7 × 5)
- [x] Badge grid (unlocked / locked) — `dawnWarrior7`, `dawnWarrior30`, etc.
- [x] Badge unlock via Cloud Function (`checkBadges`) at end of local day

### Qibla & Ramadan
- [x] Qibla screen — compass, degree, distance to Mecca
- [x] Permission + sensor error handling
- [x] Ramadan mode — auto-detect Hijri month 9 + manual toggle
- [x] Iftar countdown + Suhoor time on home screen
- [x] Fasting-hours notification muting for circle alerts

### Settings & Profile
- [x] Calculation method + madhab pickers
- [x] Language (EN/AR), theme (system/light/dark), Arabic numerals, Ramadan toggle
- [x] Display name editable
- [x] Sign out + delete account flows

### Firebase & Cloud Functions
- [x] Firebase project linked — **wazebapp** (`lib/firebase_options.dart`)
- [x] Google Sign-In OAuth clients in `google-services.json`
- [x] Firestore rules deployed (circles, circle_lookup, dua_requests, islamic_data, prayer_logs)
- [x] Cloud Functions: `checkMissedPrayers`, `checkBadges`, `syncIslamicData`
- [x] AlAdhan REST API integration (client + server) with local `adhan` fallback
- [ ] FCM production token refresh verified on physical device

### Home shell
- [x] Bottom navigation: Home | Planner | Places | Commute | Community | Analytics
- [x] All six tabs fully functional

---

## In progress / known gaps

| Item | Status |
|------|--------|
| Code coverage | **62.9%** (3193/5074 lines) — target 80% |
| Release app bundle | Failed — NDK debug-symbol stripping issue |
| APK size | 68.4 MB (target < 50 MB) |
| Manual device QA | Permissions, FCM, Qibla compass, cold start, 320dp layout |
| `genhtml` HTML coverage report | Not installed on dev machine (lcov.info available) |
| Map picker screen tests | 0% coverage |
| Onboarding provider tests | 10.9% coverage |

### Coverage hotspots under 70%
- `lib/features/locations/screens/map_picker_screen.dart` — 0%
- `lib/features/prayer/providers/prayer_provider.dart` — 37.8%
- `lib/features/onboarding/providers/onboarding_provider.dart` — 10.9%
- `lib/features/commute/providers/commute_provider.dart` — 34.6%
- `lib/features/community/providers/circles_provider.dart` — 60.7%
- `lib/features/qibla/screens/qibla_screen.dart` — 18.6%
- `lib/core/services/notification_service.dart` — 5.9%

---

## Setup status

| Item | Status |
|------|--------|
| Flutter SDK | 3.44.0 at `%LOCALAPPDATA%\flutter\bin\flutter.bat` |
| Dependencies | Installed |
| Firebase config | **wazebapp** |
| Google Sign-In | Debug SHA-1 registered; release SHA-1 needed for Play Store |
| ORS API key | In `.env` (see `.env.example`) |
| App run tested | Verified on device (SM S938B) |
| Firestore rules | Deployed |
| Cloud Functions | Deployed (`checkMissedPrayers`, `checkBadges`, `syncIslamicData`) |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` (68.4 MB) |
| Release AAB | Blocked by NDK toolchain |

---

## File structure

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── models/user_settings.dart
│   ├── providers/ (router, app_preferences)
│   ├── services/ (notification, home_widget)
│   ├── theme/app_theme.dart
│   └── utils/ (app_format, device_timezone)
├── l10n/ (EN + AR)
└── features/
    ├── auth/
    ├── onboarding/
    ├── prayer/          ← calculator, cache, AlAdhan sync, provider, panel
    ├── planner/         ← engine, blocks, calendar, ramadan meal plan
    ├── locations/       ← saved places, Nominatim, map picker, ORS
    ├── commute/         ← ORS routing, verdict, mosque finder
    ├── community/       ← circles, feed, dua board, FCM, status
    ├── analytics/       ← streaks, badges, charts, correlation
    ├── qibla/
    ├── settings/
    ├── profile/
    └── home/            ← home screen, shell, ramadan widgets

functions/src/
├── index.ts             ← checkMissedPrayers, checkBadges, syncIslamicData
├── aladhan_service.ts
├── prayer_times_service.ts
└── local_prayer_calculator.ts

test/
├── unit/                ← 28 test files
├── widget/              ← 18 test files
├── integration/         ← 11 test files
├── golden/              ← light + Arabic RTL
├── e2e/                 ← full user journey simulation
└── helpers/test_helpers.dart
```

---

## Testing

Automated test suite: **189 tests, all passing**

| Suite | Files | Status |
|-------|-------|--------|
| Unit | 28 | ✅ |
| Widget | 18 | ✅ |
| Integration | 11 | ✅ |
| Golden | 2 | ✅ |
| E2E | 1 | ✅ |
| **Total** | **189** | **✅** |

```bash
flutter test                    # all tests
flutter test --coverage         # generates coverage/lcov.info
flutter analyze                 # 0 errors, 0 warnings
```

**Coverage:** 62.9% line coverage (3193 / 5074 lines)

### Bugs fixed (recent)
- Circle create — `PERMISSION_DENIED` on invite-code query → `circle_lookup` collection + batch write
- Qibla — permission request + sensor error handling
- Early prayer check-off — gated until `prayer.isPassed`
- Countdown flicker — `select(nextPrayer?.time.millisecondsSinceEpoch)` instead of full object
- Badges — timezone + Cloud Function scheduling window widened to 23:45–23:59
- HomeWidget timer — `testMode` flag prevents hung widget/integration tests
- Tromsø polar latitude — nearest-day fallback when `adhan` returns NaN
- Firestore prayer log doc IDs — aligned to `PrayerName.dhuhr.name` (lowercase)

---

## Next steps

1. **Fix NDK toolchain** — unblock `flutter build appbundle --release`
2. **Raise coverage to 80%** — prioritize `prayer_provider`, `map_picker_screen`, `onboarding_provider`, `commute_provider`
3. **Manual device QA** — FCM, notifications, Qibla compass, cold start, small screens
4. **APK size reduction** — audit assets/deps, consider `--analyze-size`
5. **Play Store prep** — release SHA-1, privacy policy, store listing
6. **Install lcov** — `genhtml coverage/lcov.info -o coverage/html` for visual report

---

## Auth flow

```
Not logged in        →  /login
Logged in, no setup  →  /onboarding
Fully configured     →  / (home + bottom nav)
```

---

## Firestore schema (in use)

```
users/{uid}
├── (profile: email, displayName, createdAt, circleIds, fcmToken)
├── settings/preferences
│   ├── onboardingComplete, calculationMethod, madhab
│   ├── latitude, longitude, locationLabel, homeAddress
│   ├── locale, themeMode, arabicNumerals, ramadanMode
│   └── updatedAt
├── prayer_logs/{yyyy-MM-dd}/entries/{prayerName}
│   ├── checkedOff, status (completed | missed | pending)
│   └── loggedAt
├── saved_locations/{locationId}
│   ├── name, address, latitude, longitude, kind
│   └── updatedAt
├── routine_blocks/{blockId}
│   ├── title, location, locationId
│   ├── startHour/Minute, endHour/Minute, daysOfWeek[], colorValue
│   └── updatedAt
├── status
│   ├── current (active | traveling | excused | in_exam)
│   └── expiresAt, updatedAt
└── islamic_data/{document}
    └── AlAdhan sync cache

circles/{circleId}
├── name, createdBy, members[], inviteCode, groupStreak
└── updatedAt

circle_lookup/{inviteCode}
├── circleId, createdBy
└── (read: signed-in; create: owner)

circles/{circleId}/dua_requests/{requestId}
├── authorUid, authorName, message, createdAt, duaSenders[]
```

---

## Prayer times architecture

```
┌─────────────────────────────────────────────────────────┐
│  Client (instant, offline)                              │
│  adhan package → PrayerCalculator → UI                  │
│  SharedPreferences cache → cold start                   │
│  AlAdhanSyncService → once/day background sync          │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│  Cloud Functions (server-side verification)             │
│  AlAdhan REST API → prayer_times_service                │
│  local adhan npm fallback                               │
│  checkMissedPrayers / checkBadges use synced times      │
└─────────────────────────────────────────────────────────┘
```
