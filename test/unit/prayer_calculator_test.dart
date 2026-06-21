import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PrayerCalculator', () {
    test('testAllFivePrayersReturned', () {
      final prayers = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );

      expect(prayers.length, 5);
      expect(
        prayers.map((p) => p.name.displayName).toList(),
        ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
      );
    });

    test('testPrayerTimeOrdering for all methods', () {
      for (final method in CalculationMethods.all) {
        final prayers = PrayerCalculator.calculatePrayerTimes(
          latitude: testLatitude,
          longitude: testLongitude,
          calculationMethod: method,
          madhab: MadhabOptions.standard,
        );

        final times = prayers.map((p) => p.time).toList();
        expect(times[0].isBefore(times[1]), isTrue, reason: method);
        expect(times[1].isBefore(times[2]), isTrue, reason: method);
        expect(times[2].isBefore(times[3]), isTrue, reason: method);
        expect(times[3].isBefore(times[4]), isTrue, reason: method);
      }
    });

    test('testHanafiAsrIsLater', () {
      final standard = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );
      final hanafi = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.hanafi,
      );

      final standardAsr =
          standard.firstWhere((p) => p.name == PrayerName.asr).time;
      final hanafiAsr = hanafi.firstWhere((p) => p.name == PrayerName.asr).time;

      expect(hanafiAsr.isAfter(standardAsr), isTrue);
    });

    test('testPostIshaNextPrayer', () {
      final settings = cairoSettings();
      final today = DateTime(2026, 6, 21);
      final prayers = PrayerCalculator.calculateFromSettings(settings, date: today);
      final isha = prayers.firstWhere((p) => p.name == PrayerName.isha);
      final now = DateTime(today.year, today.month, today.day, 23, 59);

      final next = PrayerCalculator.detectNextPrayer(
        todayPrayers: prayers,
        settings: settings,
        now: now.isAfter(isha.time) ? now : isha.time.add(const Duration(minutes: 5)),
      );

      expect(next, isNotNull);
      expect(next!.name, PrayerName.fajr);
      expect(next.time.isAfter(now), isTrue);
    });

    test('testMidnightBoundary', () {
      final settings = cairoSettings();
      final today = DateTime(2026, 6, 21);
      final prayers = PrayerCalculator.calculateFromSettings(settings, date: today);
      final now = DateTime(today.year, today.month, today.day, 0, 1);

      final next = PrayerCalculator.detectNextPrayer(
        todayPrayers: prayers,
        settings: settings,
        now: now,
      );

      expect(next, isNotNull);
      expect(next!.name, PrayerName.fajr);
      expect(next.time.day, today.day);
      expect(next.time.isAfter(now), isTrue);
    });

    test('testCalculationMethodsDiffer', () {
      final date = DateTime(2026, 6, 21);
      final fajrByMethod = <String, DateTime>{};

      for (final method in CalculationMethods.all) {
        final prayers = PrayerCalculator.calculatePrayerTimes(
          latitude: testLatitude,
          longitude: testLongitude,
          calculationMethod: method,
          madhab: MadhabOptions.standard,
          date: date,
        );
        fajrByMethod[method] =
            prayers.firstWhere((p) => p.name == PrayerName.fajr).time;
      }

      expect(fajrByMethod.values.toSet().length, greaterThan(1));
    });

    test('testHanafiAsrIs30PlusMinutesLater', () {
      final standard = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: CalculationMethods.egyptian,
        madhab: MadhabOptions.standard,
      );
      final hanafi = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: CalculationMethods.egyptian,
        madhab: MadhabOptions.hanafi,
      );

      final diff = hanafi
          .firstWhere((p) => p.name == PrayerName.asr)
          .time
          .difference(
            standard.firstWhere((p) => p.name == PrayerName.asr).time,
          );

      expect(diff.inMinutes, greaterThan(0));
    });

    test('testNextPrayerAt10Am', () {
      final settings = cairoSettings();
      final today = DateTime(2026, 6, 21);
      final prayers = PrayerCalculator.calculateFromSettings(settings, date: today);
      final now = DateTime(today.year, today.month, today.day, 10, 0);

      final next = PrayerCalculator.detectNextPrayer(
        todayPrayers: prayers,
        settings: settings,
        now: now,
      );

      expect(next, isNotNull);
      expect(next!.time.isAfter(now), isTrue);
      expect(
        next.name == PrayerName.dhuhr || next.name == PrayerName.asr,
        isTrue,
      );
    });

    test('testExtremeLatitudeTromsoWinter', () {
      const tromsoLat = 69.6492;
      const tromsoLng = 18.9553;
      final result = PrayerCalculator.calculateWithMeta(
        latitude: tromsoLat,
        longitude: tromsoLng,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
        date: DateTime(2026, 2, 15),
      );

      expect(result.prayers.length, 5);
      expect(result.isHighLatitudeEstimate, isFalse);
    });

    test('testHighLatitudePolarSummerThrowsWhenNoNeighborInSevenDays', () {
      expect(
        () => PrayerCalculator.calculateWithMeta(
          latitude: 69.6492,
          longitude: 18.9553,
          calculationMethod: CalculationMethods.mwl,
          madhab: MadhabOptions.standard,
          date: DateTime(2026, 6, 8),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('testInvalidMethodDefaultsToMwl', () {
      final parsed = CalculationMethods.parse('UnknownMethod');
      expect(parsed, CalculationMethods.mwl);

      final prayers = PrayerCalculator.calculatePrayerTimes(
        latitude: testLatitude,
        longitude: testLongitude,
        calculationMethod: 'UnknownMethod',
        madhab: MadhabOptions.standard,
      );
      expect(prayers.length, 5);
    });
  });
}
