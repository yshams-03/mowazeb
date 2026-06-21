import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/features/prayer/models/hijri_date_info.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_sync_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AlAdhanSyncService.getHijriDate', () {
    test('returns cached hijri when valid prefs exist', () async {
      const cached = HijriDateInfo(
        day: 15,
        monthNum: 9,
        monthEn: 'Ramadan',
        monthAr: 'رمضان',
        year: 1447,
      );
      await PrayerCacheService.instance.saveHijriDate(cached);

      final result = await AlAdhanSyncService.getHijriDate();

      expect(result.day, 15);
      expect(result.monthEn, 'Ramadan');
    });

    test('falls back to hijri package when cache missing', () async {
      final result = await AlAdhanSyncService.getHijriDate();

      expect(result.day, greaterThan(0));
      expect(result.year, greaterThan(1400));
    });
  });
}
