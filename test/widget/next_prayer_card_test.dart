import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/theme/app_theme.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/prayer/widgets/next_prayer_card.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('NextPrayerCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required PrayerTimeModel nextPrayer,
      required Duration timeUntil,
      ThemeData? theme,
    }) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          theme: theme,
          overrides: [
            prayerStateOverride(
              PrayerState(
                todaysPrayers: cairoPrayers(),
                nextPrayer: nextPrayer,
                isLoading: false,
              ),
            ),
            countdownOverride(timeUntil),
          ],
          child: const Scaffold(body: NextPrayerCard()),
        ),
      );
      await tester.pump();
    }

    testWidgets('testCardRendersWithPrayerName', (tester) async {
      final asr = cairoPrayers().firstWhere((p) => p.name == PrayerName.asr);
      await pumpCard(
        tester,
        nextPrayer: asr,
        timeUntil: const Duration(minutes: 45),
      );

      expect(find.text('Asr'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('testCountdownFormatLong', (tester) async {
      final dhuhr = cairoPrayers().firstWhere((p) => p.name == PrayerName.dhuhr);
      await pumpCard(
        tester,
        nextPrayer: dhuhr,
        timeUntil: const Duration(minutes: 90),
      );

      expect(find.textContaining('1h 30m'), findsOneWidget);
    });

    testWidgets('testCountdownFormatShort', (tester) async {
      final dhuhr = cairoPrayers().firstWhere((p) => p.name == PrayerName.dhuhr);
      await pumpCard(
        tester,
        nextPrayer: dhuhr,
        timeUntil: const Duration(seconds: 45),
      );

      expect(find.textContaining('45s'), findsOneWidget);
    });

    testWidgets('testCardDarkMode', (tester) async {
      final dhuhr = cairoPrayers().firstWhere((p) => p.name == PrayerName.dhuhr);
      await pumpCard(
        tester,
        nextPrayer: dhuhr,
        timeUntil: const Duration(minutes: 10),
        theme: AppTheme.dark,
      );

      expect(find.byType(Text), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
