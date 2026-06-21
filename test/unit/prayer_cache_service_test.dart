import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_cache_service.dart';

void main() {
  group('PrayerCacheService', () {
    late UserSettings settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settings = const UserSettings(
        onboardingComplete: true,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
        latitude: 30.0444,
        longitude: 31.2357,
      );
    });

    test('save and load same-day cache', () async {
      const dateKey = '2025-06-21';
      final prayers = [
        PrayerTimeModel(
          name: PrayerName.fajr,
          time: DateTime(2025, 6, 21, 4, 8),
        ),
        PrayerTimeModel(
          name: PrayerName.dhuhr,
          time: DateTime(2025, 6, 21, 12, 57),
        ),
        PrayerTimeModel(
          name: PrayerName.asr,
          time: DateTime(2025, 6, 21, 16, 32),
        ),
        PrayerTimeModel(
          name: PrayerName.maghrib,
          time: DateTime(2025, 6, 21, 19, 59),
        ),
        PrayerTimeModel(
          name: PrayerName.isha,
          time: DateTime(2025, 6, 21, 21, 33),
        ),
      ];

      await PrayerCacheService.instance.save(
        dateKey: dateKey,
        prayers: prayers,
        settings: settings,
      );

      final loaded = await PrayerCacheService.instance.load(dateKey, settings);
      expect(loaded, isNotNull);
      expect(loaded!.prayers.length, 5);
      expect(loaded.prayers.first.name, PrayerName.fajr);
    });

    test('returns null when date key differs', () async {
      final prayers = List.generate(
        5,
        (i) => PrayerTimeModel(
          name: PrayerName.values[i],
          time: DateTime(2025, 6, 21, i + 1),
        ),
      );

      await PrayerCacheService.instance.save(
        dateKey: '2025-06-21',
        prayers: prayers,
        settings: settings,
      );

      final loaded = await PrayerCacheService.instance.load('2025-06-22', settings);
      expect(loaded, isNull);
    });

    test('tracks last sync date', () async {
      expect(await PrayerCacheService.instance.lastSyncDateKey(), isNull);
      await PrayerCacheService.instance.markSynced('2025-06-21');
      expect(await PrayerCacheService.instance.lastSyncDateKey(), '2025-06-21');
    });
  });
}
