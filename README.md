# mowazeb

![CI](https://github.com/yshams-03/mowazeb/actions/workflows/ci.yml/badge.svg)

mowazeb is a Flutter app for keeping daily prayers on time when the rest of the day is already scheduled. It calculates the five prayer times on the device, lets you check them off, and fits them into a weekly routine, a drive home, and a small accountability circle. The interface is English and Arabic (with RTL layout), and settings, places, routines, and circle activity are stored in Cloud Firestore. The in-app name and tagline are **mowazeb** and **Never miss a prayer**. The Dart package is still `ummah_pulse`.

Current app version in `pubspec.yaml`: **1.0.1+2**.

## Features

- **Prayer times.** Offline calculation with the `adhan` package, a local cache for cold start, and a once-per-day background sync against the AlAdhan API. Calculation methods are Muslim World League, ISNA, Egyptian, Umm al-Qura, and Karachi. Asr follows Standard or Hanafi. If a high-latitude day cannot be calculated, the client searches up to seven days backward. The home screen shows today's times, Hijri date, the next prayer, and a countdown, and it recalculates after a pull-to-refresh or when GPS reports a move of about 500 meters.
- **Check-off.** Each prayer can be marked done after its time has passed. Logs are stored under the signed-in user.
- **Onboarding.** Three steps: location permission, calculation method, then madhab. Completing them writes `users/{uid}/settings/preferences`.
- **Accounts.** Email/password registration and sign-in, plus Google sign-in. Settings can sign out or delete the account after a confirmation dialog.
- **Smart Day Planner.** Weekly routine blocks (title, saved place, start, end, weekdays, color). A prayer that falls inside a block is tagged at that place. A prayer in the 15 minutes after a block ends is tagged as a transition and can schedule a local wudu reminder 10 minutes before the prayer. Anything else is tagged at home.
- **Places.** Save Home, Work, and custom places. Search uses Nominatim, a short list of abbreviations (for example `aast`), and a geocoding fallback. A map picker drops a pin on OpenStreetMap tiles. Reverse geocoding uses OpenRouteService when `ORS_API_KEY` is set, and Nominatim otherwise.
- **Smart Commute Advisor.** Compares driving time from the current location to Home (OpenRouteService) with the time left until the next prayer. The verdict is green when the drive fits, and red when the prayer has passed or the drive is longer. On red, the screen can list up to three nearby mosques from OpenStreetMap (2 km, Overpass) with a Google Maps directions link.
- **Accountability circles.** Create a circle or join one with a 6-character invite code. The circle shows a live prayer feed, member rows, and a group streak. A dua board accepts requests from members. A presence status of Active, Traveling, Excused, or In Exam is shown with a public label only. Traveling, Excused, and In Exam skip missed-prayer alerts.
- **Analytics.** A tab marked private to the signed-in user: personal and group streaks, a 30-day completion chart, per-prayer timing, schedule insights, an 8-week heatmap, and badges (Dawn Warrior, 30-Day Dawn Warrior, Perfect Week, Early Bird, Night Owl, Circle Champion).
- **Qibla.** Compass direction and distance to Mecca from the device sensors and the saved location.
- **Ramadan.** Turns on automatically in Hijri month 9, or can be forced on or off. While it is active, home shows an iftar countdown until Maghrib, and the planner can show suhoor (20 minutes before Fajr) and iftar (Maghrib). During fasting hours, circle missed-prayer pushes are muted.
- **Home screen widget.** Android `PrayerWidgetProvider` refreshes the next prayer about once a minute.
- **Appearance.** System, light, or dark theme (green/teal Material 3), English or Arabic, and an Arabic-numerals toggle.

The per-prayer switches under Settings are saved on the user profile as `notificationPrayers`. This repository schedules a local notification for the wudu reminder above. Missed-prayer and dua pushes are sent by Cloud Functions through FCM.

## Tech stack

| Area | Choice |
| --- | --- |
| App | Flutter, Dart SDK `>=3.2.0 <4.0.0` |
| State | flutter_riverpod |
| Navigation | go_router, with redirects for auth and onboarding |
| Backend | Firebase Auth, Cloud Firestore, Cloud Functions (Node.js 20), FCM, App Check |
| Prayer math | `adhan` on device; AlAdhan HTTP API for the daily sync |
| Maps and routing | flutter_map, OpenStreetMap, Nominatim, OpenRouteService, Overpass |
| Location and sensors | geolocator, geocoding, flutter_qiblah |
| Charts | fl_chart |
| Localization | flutter gen-l10n (`lib/l10n`, English and Arabic) |

Firebase project id in this repo: **wazebapp**.

## Project structure

```
lib/
├── main.dart                 # dotenv, Firebase, notifications, home widget
├── app.dart                  # theme, locale, router, splash
├── firebase_options.dart     # FlutterFire options for wazebapp
├── core/                     # theme, routes, Firestore paths, notifications
├── l10n/                     # generated English and Arabic strings
└── features/
    ├── auth/                 # email and Google sign-in
    ├── onboarding/
    ├── prayer/
    ├── home/                 # prayer panel, Ramadan cards, bottom nav
    ├── planner/
    ├── locations/            # saved places and map picker
    ├── commute/
    ├── community/            # circles, dua board, presence
    ├── analytics/
    ├── qibla/
    ├── profile/
    └── settings/
functions/src/                # scheduled and callable Cloud Functions
firestore.rules
test/                         # unit, widget, integration, and golden tests
android/ ios/ web/            # plus windows/, macos/, linux/
```

Bottom navigation after onboarding: Home, Planner, Places, Commute, Community, Analytics. Profile, Settings, and Qibla are pushed routes.

### Routing

```
Signed out            → /login or /register
Signed in, setup left → /onboarding
Setup complete        → /  (home shell)
```

### Firestore paths the app writes

```
users/{uid}
users/{uid}/settings/preferences
users/{uid}/prayer_logs/{date}/prayers/{prayerName}
users/{uid}/routine_blocks/{id}
users/{uid}/saved_locations/{id}
users/{uid}/status
users/{uid}/fcmToken
users/{uid}/streak
users/{uid}/badges/{badgeId}
circles/{circleId}
circles/{circleId}/dua_requests/{id}
circles/{circleId}/streak
circle_lookup/{inviteCode}
```

Rules live in `firestore.rules`. Circle members can read each other's prayer logs; analytics copy in the UI says the charts are private to the signed-in user.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) stable. These steps were run with Flutter **3.47.5** (Dart 3.13.4).
- For a device build: Android SDK, Xcode, or Chrome. `lib/firebase_options.dart` has no Linux options, so `flutter run -d linux` throws `UnsupportedError`.
- Optional, for commute routing: a free [OpenRouteService](https://openrouteservice.org/dev/#/signup) API key.
- Optional, to compile Cloud Functions: Node.js 20 (the version in `functions/package.json`). `npm ci && npm run build` also completed on Node.js 22, with an engines warning.
- Optional, to deploy rules or functions: the [Firebase CLI](https://firebase.google.com/docs/cli), logged into a project you control.

Platform folders are already in the repo. Android location and notification permissions are in `android/app/src/main/AndroidManifest.xml`. iOS location usage strings are in `ios/Runner/Info.plist`. A normal checkout continues with the commands below. `setup.ps1` is a Windows helper that calls `flutter create` against `%LOCALAPPDATA%\flutter\bin\flutter.bat` and can overwrite those platform files.

## Setup

From the repository root:

```bash
cp .env.example .env
flutter pub get
```

Both commands completed on Flutter 3.47.5. `.env` is gitignored. Prayer times, places search, and the map picker work with `ORS_API_KEY` left empty. The commute screen needs a key before it can request a driving route.

The checked-in Firebase options already point at project `wazebapp`. Signing in depends on that project's Authentication providers, which are configured in the Firebase console rather than in this repository. To use your own Firebase project instead:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
firebase deploy --only firestore:rules
```

Then enable Email/Password and Google in that project's Authentication settings. For Google sign-in on Android, register the debug (and later release) SHA-1 for application id `com.ummahpulse.ummah_pulse`.

Cloud Functions, from `functions/`:

```bash
npm ci
npm run build
```

That compiles `functions/src` to `functions/lib` (gitignored). Deploy with `npm run deploy` inside `functions/`, or `firebase deploy --only functions` from the repository root. The exported functions are:

| Function | Trigger |
| --- | --- |
| `checkMissedPrayers` | every 30 minutes |
| `calculateStreaksAndBadges` | every 60 minutes, at the end of the user's local day |
| `sendPrayerReminder` | callable |
| `sendDua` | callable |
| `sendDuaForMissedPrayer` | callable |
| `syncIslamicData` | callable |

## Run

```bash
flutter run
```

Pick an Android or iOS device, an emulator, or Chrome (`flutter run -d chrome`). The first screen is email/password sign-in, Google sign-in, or a link to register. After registration the app opens onboarding, then the home shell.

Release Android signing is optional and is described in `android/keystore.properties.example`. Do not commit a keystore.

## Tests

```bash
flutter analyze --fatal-warnings
flutter test
```

On Flutter 3.47.5 in this environment:

- `flutter analyze --fatal-warnings` printed **9 info-level lints** and no errors or warnings, then exited 1. The info hits are `prefer_const_*`, one deprecated `Color.value` use, `library_private_types_in_public_api`, and a `fake_async` import in tests.
- `flutter test` finished **381 passed, 3 failed**. The failures were golden pixel diffs in `test/golden/home_screen_golden_test.dart` and `test/golden/arabic_rtl_golden_test.dart` (about 0.17% and 0.20%), and `PrayerNotifier calculatePrayers loads from cache first` in `test/unit/prayer_provider_test.dart` (expected cached Fajr hour 4, got 2) on a UTC machine.

CI (`.github/workflows/ci.yml`) runs analyze, `flutter test --coverage`, an 80% line-coverage gate, and `flutter build apk --release` on pushes and pull requests to `main` and `develop`. Coverage was not re-measured in this pass. `coverage/lcov.info` is already committed; new coverage output is gitignored.

## Screenshots

TODO: add a real screenshot of the running app, for example the sign-in screen or the home prayer panel, at `docs/screenshots/`.

A screenshot is omitted because the web build did not reach a Flutter frame in this environment. `flutter run -d web-server` compiled, then FlutterFire threw during startup in headless Chrome (`ArgumentError` inside `firebase_app_check` / `firebase_auth`) while the HTML splash was still showing. No Android emulator was available.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE). Copyright 2026 Yasin Shams.
