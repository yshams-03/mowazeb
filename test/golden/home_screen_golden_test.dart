import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/theme/app_theme.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/models/hijri_date_info.dart';
import 'package:ummah_pulse/features/prayer/providers/hijri_date_provider.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/prayer/widgets/prayer_times_panel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Home screen golden', () {
    testWidgets('light mode prayer panel layout', (tester) async {
      setLargeScreen(tester);
      final prayers = cairoPrayers();
      await tester.pumpWidget(
        buildTestApp(
          theme: AppTheme.light,
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: prayers,
                nextPrayer: prayers.firstWhere((p) => p.name == PrayerName.dhuhr),
                isLoading: false,
              ),
            ),
            countdownOverride(const Duration(minutes: 45)),
            hijriDateProvider.overrideWith(
              (ref) async => const HijriDateInfo(
                day: 25,
                monthNum: 12,
                monthEn: 'Dhul Hijjah',
                monthAr: 'ذو الحجة',
                year: 1447,
              ),
            ),
          ],
          child: const Scaffold(body: PrayerTimesPanel()),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PrayerTimesPanel),
        matchesGoldenFile('goldens/home_light.png'),
      );
    });
  });
}
