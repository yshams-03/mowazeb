import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/prayer/widgets/prayer_times_panel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PrayerTimesPanel', () {
    testWidgets('shows countdown on next prayer row', (tester) async {
      final prayers = cairoPrayers();
      final dhuhr = prayers.firstWhere((p) => p.name == PrayerName.dhuhr);
      final annotated = prayers
          .map((p) => p.copyWith(isNext: p.name == PrayerName.dhuhr))
          .toList();

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            prayerStateOverride(
              PrayerState(
                todaysPrayers: annotated,
                nextPrayer: dhuhr,
                isLoading: false,
              ),
            ),
            countdownOverride(const Duration(hours: 8, minutes: 4, seconds: 9)),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(
                cairoSettings().copyWith(locationLabel: 'Cairo, Egypt'),
              ),
            ),
          ],
          child: const Scaffold(body: PrayerTimesPanel()),
        ),
      );
      await tester.pump();

      expect(find.text('8:04:09'), findsOneWidget);
      expect(find.text('Dhuhr'), findsOneWidget);
    });

    testWidgets('lists all five prayers', (tester) async {
      final prayers = cairoPrayers();
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            prayerStateOverride(
              PrayerState(
                todaysPrayers: prayers,
                nextPrayer: prayers.firstWhere((p) => p.name == PrayerName.dhuhr),
                isLoading: false,
              ),
            ),
            countdownOverride(const Duration(minutes: 30)),
          ],
          child: const Scaffold(body: PrayerTimesPanel()),
        ),
      );
      await tester.pump();

      for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });

  group('formatCountdownCompact', () {
    test('formats hours minutes seconds', () {
      expect(
        formatCountdownCompact(const Duration(hours: 8, minutes: 4, seconds: 9)),
        '8:04:09',
      );
    });
  });
}
