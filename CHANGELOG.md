# Changelog

All notable changes to UmmahPulse (mowazeb) are documented in this file.

## [1.0.1+2] - 2026-06-21

### Quality
- Reached **80% line test coverage** (4162/5205 lines, 387 tests passing) with extended widget and unit tests across Qibla, auth, onboarding, locations, community, commute, profile, and settings.
- `flutter analyze` — 0 errors, 0 warnings.

### Prayer & sync
- Hardened AlAdhan REST client (Unix timestamp endpoint, full Hijri parsing, once-per-day background sync).
- Fixed Firestore path for Islamic data sync documents.
- High-latitude prayer-time fallback (7-day backward search) in client and Cloud Functions.

### Release prep
- Bumped app version to 1.0.1+2.
- Added ProGuard keep rules for Firebase, Google Play Services, and Flutter.
- Scaffolded `keystore.properties`-based release signing for Play Store builds.

## [1.0.0+1] - 2026-06-21

### Added
- Initial release: prayer times, Smart Day Planner, saved places, Smart Commute Advisor, accountability circles, analytics, Qibla compass, Ramadan mode, bilingual EN/AR UI, and settings.
