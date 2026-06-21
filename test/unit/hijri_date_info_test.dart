import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/prayer/models/hijri_date_info.dart';

void main() {
  group('HijriDateInfo', () {
    test('fromAlAdhanJson parses nested month fields', () {
      final info = HijriDateInfo.fromAlAdhanJson({
        'day': '15',
        'year': '1447',
        'month': {
          'number': 9,
          'en': 'Ramadan',
          'ar': 'رمضان',
        },
      });

      expect(info.day, 15);
      expect(info.monthNum, 9);
      expect(info.monthEn, 'Ramadan');
      expect(info.monthAr, 'رمضان');
      expect(info.year, 1447);
    });

    test('fromAlAdhanJson falls back when month map missing', () {
      final info = HijriDateInfo.fromAlAdhanJson({
        'day': 'bad',
        'year': 'bad',
      });

      expect(info.day, 1);
      expect(info.monthNum, 1);
      expect(info.monthEn, isEmpty);
    });

    test('fromHijriPackage builds from current date', () {
      final info = HijriDateInfo.fromHijriPackage(DateTime(2026, 6, 21));

      expect(info.day, greaterThan(0));
      expect(info.monthNum, greaterThan(0));
      expect(info.monthEn, isNotEmpty);
      expect(info.year, greaterThan(1400));
    });

    test('fromPrefs and toPrefs round-trip', () {
      const info = HijriDateInfo(
        day: 10,
        monthNum: 3,
        monthEn: 'Rabi al-awwal',
        monthAr: 'ربيع الأول',
        year: 1446,
      );

      final restored = HijriDateInfo.fromPrefs(info.toPrefs());

      expect(restored.day, 10);
      expect(restored.monthNum, 3);
      expect(restored.monthEn, 'Rabi al-awwal');
      expect(restored.monthAr, 'ربيع الأول');
      expect(restored.year, 1446);
    });

    test('formatEnglish and formatArabic render readable strings', () {
      const info = HijriDateInfo(
        day: 5,
        monthNum: 9,
        monthEn: 'Ramadan',
        monthAr: 'رمضان',
        year: 1447,
      );

      expect(info.formatEnglish(), '5 Ramadan 1447');
      expect(info.formatArabic(arabicNumerals: false), '5 رمضان 1447');
      expect(info.formatArabic(arabicNumerals: true), contains('رمضان'));
      expect(info.formatArabic(arabicNumerals: true), isNot(contains('5')));
    });

    test('formatEnglish omits month name when empty', () {
      const info = HijriDateInfo(
        day: 2,
        monthNum: 1,
        monthEn: '',
        monthAr: '',
        year: 1440,
      );

      expect(info.formatEnglish(), '2 1440');
    });

    test('fromAlAdhanJson uses English month when Arabic missing', () {
      final info = HijriDateInfo.fromAlAdhanJson({
        'day': '3',
        'year': '1447',
        'month': {'number': 1, 'en': 'Muharram'},
      });

      expect(info.monthAr, 'Muharram');
    });
  });
}
