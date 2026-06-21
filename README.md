# UmmahPulse

![CI](https://github.com/yshams-03/mowazeb/actions/workflows/ci.yml/badge.svg)

A smart lifestyle and habit app for busy Muslims — prayer times, smart planning, commute guidance, and community accountability.

## Quick Start

### 1. Install Flutter

Install [Flutter SDK](https://docs.flutter.dev/get-started/install) and ensure `flutter` is on your PATH.

### 2. Generate platform folders

The repo includes all Dart source. Platform folders (android/, ios/, etc.) are generated on first setup:

```powershell
.\setup.ps1
```

Or manually:

```bash
flutter create . --project-name ummah_pulse --org com.ummahpulse
flutter pub get
```

### 3. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This replaces `lib/firebase_options.dart` with your real project credentials.

In Firebase Console:
- Enable **Email/Password** and **Google** under Authentication
- Create a **Firestore** database
- Deploy rules: `firebase deploy --only firestore:rules`
- Add Android SHA-1 fingerprint for Google Sign-In

### 4. Platform permissions

After `flutter create`, add permissions per `platform_setup/PERMISSIONS.md`.

### 5. Run

```bash
flutter run
```

## Architecture

```
lib/
├── main.dart              # Firebase + notifications init
├── app.dart               # MaterialApp + splash loading
├── core/
│   ├── constants/         # Routes, colors, Firestore paths
│   ├── models/            # UserSettings
│   ├── providers/         # GoRouter with auth guards
│   ├── services/          # Local notifications
│   └── theme/             # Light/dark green-teal theme
└── features/
    ├── auth/              # Email + Google sign-in
    ├── onboarding/        # Location → method → madhab
    ├── prayer/            # adhan calculations + Firestore logs
    └── home/              # Home screen + bottom nav shell
```

## Auth Flow

```
Not logged in     → Login / Register
Logged in         → Onboarding (if incomplete)
Onboarding done   → Home (bottom nav)
```

## Firestore Schema

```
users/{uid}
  └── settings/preferences   → calculationMethod, madhab, lat/lng, onboardingComplete
  └── prayer_logs/{date}   → daily prayer times snapshot
```

## Tech Stack

- **Flutter** + **Riverpod** — UI and state
- **Firebase Auth** — email/password + Google
- **Cloud Firestore** — user settings and prayer logs
- **adhan** + **geolocator** — local prayer time calculation
- **go_router** — declarative navigation with redirects
- **flutter_local_notifications** — notification infrastructure (ready for nudges)
