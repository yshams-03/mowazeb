import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF1B8A6B);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentGold = Color(0xFFD4A843);
  static const Color lightBackground = Color(0xFFF5FAF8);
  static const Color darkBackground = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF151B26);
  static const Color darkCard = Color(0xFF1E2736);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);
}

class AppStrings {
  AppStrings._();

  static const String appName = 'mowazeb';
  static const String tagline = 'Never miss a prayer';

  static const List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];
}

class CalculationMethods {
  CalculationMethods._();

  static const String mwl = 'MWL';
  static const String isna = 'ISNA';
  static const String egyptian = 'Egyptian';
  static const String ummAlQura = 'Umm al-Qura';
  static const String karachi = 'Karachi';

  static const List<String> all = [
    mwl,
    isna,
    egyptian,
    ummAlQura,
    karachi,
  ];

  /// Parses a stored method string; unknown values default to [mwl].
  static String parse(String? value) {
    if (value == null) return mwl;
    if (all.contains(value)) return value;
    return mwl;
  }
}

class MadhabOptions {
  MadhabOptions._();

  static const String standard = 'Standard';
  static const String hanafi = 'Hanafi';

  static const List<String> all = [standard, hanafi];
}

class FirestorePaths {
  FirestorePaths._();

  static String userDoc(String uid) => 'users/$uid';
  static String userSettings(String uid) => 'users/$uid/settings/preferences';
  static String prayerLog(String uid, String date) =>
      'users/$uid/prayer_logs/$date';
  static String routineBlocks(String uid) => 'users/$uid/routine_blocks';
  static String routineBlock(String uid, String blockId) =>
      'users/$uid/routine_blocks/$blockId';
  static String savedLocations(String uid) => 'users/$uid/saved_locations';
  static String savedLocation(String uid, String locationId) =>
      'users/$uid/saved_locations/$locationId';
  static String circles() => 'circles';
  static String circle(String circleId) => 'circles/$circleId';
  static String prayerLogEntry(
    String uid,
    String date,
    String prayerName,
  ) =>
      'users/$uid/prayer_logs/$date/prayers/$prayerName';
  static String prayerLogEntries(String uid, String date) =>
      'users/$uid/prayer_logs/$date/prayers';
  static String userFcmToken(String uid) => 'users/$uid/fcmToken';
  static String userStatus(String uid) => 'users/$uid/status';
  static String duaRequests(String circleId) =>
      'circles/$circleId/dua_requests';
  static String duaRequest(String circleId, String requestId) =>
      'circles/$circleId/dua_requests/$requestId';
  static String userStreak(String uid) => 'users/$uid/streak';
  static String userBadge(String uid, String badgeId) =>
      'users/$uid/badges/$badgeId';
  static String userBadges(String uid) => 'users/$uid/badges';
  static String circleStreak(String circleId) => 'circles/$circleId/streak';
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String planner = '/planner';
  static const String places = '/places';
  static const String commute = '/commute';
  static const String community = '/community';
  static const String communityCreate = '/community/create';
  static const String communityJoin = '/community/join';
  static const String communityCircle = '/community/circle';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String qibla = '/qibla';

  /// Backward-compatible alias.
  static const String locations = places;
}
