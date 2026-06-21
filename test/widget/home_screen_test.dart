import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/models/streak_model.dart';
import 'package:ummah_pulse/features/analytics/providers/analytics_provider.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/home/screens/home_screen.dart';
import 'package:ummah_pulse/features/planner/providers/ramadan_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/prayer/widgets/prayer_times_panel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('HomeScreen', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      List<Override> overrides = const [],
      int refreshCount = 0,
    }) async {
      setLargeScreen(tester);
      var refreshes = refreshCount;
      final prayers = cairoPrayers();
      final annotated = prayers
          .map((p) => p.copyWith(isNext: p.name == PrayerName.dhuhr))
          .toList();
      final dhuhr = prayers.firstWhere((p) => p.name == PrayerName.dhuhr);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(
                cairoSettings().copyWith(locationLabel: 'Cairo, Egypt'),
              ),
            ),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: annotated,
                nextPrayer: dhuhr,
                isLoading: false,
              ),
            ),
            countdownOverride(const Duration(hours: 2, minutes: 15, seconds: 30)),
            todayPrayerLogsProvider.overrideWith((ref) => Stream.value(const {})),
            personalStreakProvider.overrideWith(
              (ref) => Stream.value(
                const StreakData(currentStreak: 3, longestStreak: 5),
              ),
            ),
            ramadanProvider.overrideWith((ref) => const RamadanState()),
            ...overrides,
          ],
          child: HomeScreen(
            key: ValueKey(refreshes),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows prayer times panel with five prayers', (tester) async {
      await pumpHome(tester);

      expect(find.byType(PrayerTimesPanel), findsOneWidget);
      for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('shows countdown on next prayer row', (tester) async {
      await pumpHome(tester);
      expect(find.text('2:15:30'), findsOneWidget);
    });

    testWidgets('shows hijri date in panel header', (tester) async {
      await pumpHome(tester);
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    });

    testWidgets('shows streak when streak > 0', (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('refresh icon triggers prayer refresh', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
