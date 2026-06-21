import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';

void main() {
  group('CalculationMethods', () {
    test('parse returns mwl for null or unknown values', () {
      expect(CalculationMethods.parse(null), CalculationMethods.mwl);
      expect(CalculationMethods.parse('Unknown'), CalculationMethods.mwl);
      expect(CalculationMethods.parse(CalculationMethods.isna), CalculationMethods.isna);
    });

    test('all lists every supported method', () {
      expect(CalculationMethods.all, contains(CalculationMethods.ummAlQura));
      expect(CalculationMethods.all.length, 5);
    });
  });

  group('MadhabOptions', () {
    test('all includes standard and hanafi', () {
      expect(MadhabOptions.all, [MadhabOptions.standard, MadhabOptions.hanafi]);
    });
  });

  group('AppStrings', () {
    test('prayerNames lists five daily prayers', () {
      expect(AppStrings.prayerNames, hasLength(5));
      expect(AppStrings.appName, isNotEmpty);
    });
  });

  group('AppColors', () {
    test('defines brand palette colors', () {
      expect(AppColors.primaryGreen, isA<Color>());
      expect(AppColors.primaryTeal.value, isNonZero);
    });
  });

  group('FirestorePaths', () {
    test('builds nested user and circle paths', () {
      expect(FirestorePaths.userDoc('uid'), 'users/uid');
      expect(FirestorePaths.userSettings('uid'), 'users/uid/settings/preferences');
      expect(FirestorePaths.prayerLog('uid', '2026-06-21'), 'users/uid/prayer_logs/2026-06-21');
      expect(FirestorePaths.userFcmToken('uid'), 'users/uid/fcmToken');
      expect(FirestorePaths.userStatus('uid'), 'users/uid/status');
      expect(FirestorePaths.duaRequests('c1'), 'circles/c1/dua_requests');
      expect(FirestorePaths.duaRequest('c1', 'r1'), 'circles/c1/dua_requests/r1');
      expect(FirestorePaths.userStreak('uid'), 'users/uid/streak');
      expect(FirestorePaths.userBadge('uid', 'badge1'), 'users/uid/badges/badge1');
      expect(FirestorePaths.userBadges('uid'), 'users/uid/badges');
      expect(FirestorePaths.circleStreak('c1'), 'circles/c1/streak');
      expect(FirestorePaths.routineBlocks('uid'), 'users/uid/routine_blocks');
      expect(FirestorePaths.routineBlock('uid', 'b1'), 'users/uid/routine_blocks/b1');
      expect(FirestorePaths.savedLocations('uid'), 'users/uid/saved_locations');
      expect(FirestorePaths.savedLocation('uid', 'loc'), 'users/uid/saved_locations/loc');
      expect(FirestorePaths.circles(), 'circles');
      expect(FirestorePaths.circle('c1'), 'circles/c1');
      expect(
        FirestorePaths.prayerLogEntry('uid', '2026-06-21', 'Fajr'),
        'users/uid/prayer_logs/2026-06-21/prayers/Fajr',
      );
      expect(
        FirestorePaths.prayerLogEntries('uid', '2026-06-21'),
        'users/uid/prayer_logs/2026-06-21/prayers',
      );
    });
  });

  group('RoutePaths', () {
    test('exposes navigation routes and aliases', () {
      expect(RoutePaths.home, '/');
      expect(RoutePaths.login, '/login');
      expect(RoutePaths.register, '/register');
      expect(RoutePaths.onboarding, '/onboarding');
      expect(RoutePaths.locations, RoutePaths.places);
      expect(RoutePaths.communityCreate, '/community/create');
      expect(RoutePaths.communityJoin, '/community/join');
      expect(RoutePaths.communityCircle, '/community/circle');
      expect(RoutePaths.community, '/community');
      expect(RoutePaths.planner, '/planner');
      expect(RoutePaths.commute, '/commute');
      expect(RoutePaths.analytics, '/analytics');
      expect(RoutePaths.profile, '/profile');
      expect(RoutePaths.settings, '/settings');
      expect(RoutePaths.qibla, '/qibla');
    });
  });
}
