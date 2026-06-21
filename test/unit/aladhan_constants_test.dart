import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_constants.dart';

void main() {
  group('AlAdhanConstants', () {
    test('maps calculation methods to AlAdhan IDs', () {
      expect(AlAdhanConstants.methodIdFor(CalculationMethods.mwl), 3);
      expect(AlAdhanConstants.methodIdFor(CalculationMethods.isna), 2);
      expect(AlAdhanConstants.methodIdFor(CalculationMethods.egyptian), 5);
      expect(AlAdhanConstants.methodIdFor(CalculationMethods.ummAlQura), 4);
      expect(AlAdhanConstants.methodIdFor(CalculationMethods.karachi), 1);
      expect(AlAdhanConstants.methodIdFor(null), 3);
    });

    test('maps madhab to school', () {
      expect(AlAdhanConstants.schoolFor(MadhabOptions.standard), 0);
      expect(AlAdhanConstants.schoolFor(MadhabOptions.hanafi), 1);
    });

    test('unix timestamp for start of local day', () {
      final ts = AlAdhanConstants.unixTimestampForDate(DateTime(2026, 6, 21));
      expect(ts, greaterThan(0));
    });

    test('formats legacy date param as DD-MM-YYYY', () {
      expect(AlAdhanConstants.dateParam('2025-06-21'), '21-06-2025');
    });
  });
}
