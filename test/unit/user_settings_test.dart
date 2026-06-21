import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

void main() {
  group('UserSettings', () {
    test('testSerializationRoundtrip preserves all fields', () {
      const original = UserSettings(
        onboardingComplete: true,
        calculationMethod: CalculationMethods.isna,
        madhab: MadhabOptions.hanafi,
        latitude: PrayerCalculator.cairoLatitude,
        longitude: PrayerCalculator.cairoLongitude,
      );

      final map = Map<String, dynamic>.from(original.toMap())
        ..remove('updatedAt');

      final restored = UserSettings.fromMap(map);

      expect(restored.onboardingComplete, original.onboardingComplete);
      expect(restored.calculationMethod, original.calculationMethod);
      expect(restored.madhab, original.madhab);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.isComplete, isTrue);
    });

    test('testDefaultValues are sensible', () {
      const settings = UserSettings();

      expect(settings.onboardingComplete, isFalse);
      expect(settings.calculationMethod, isNull);
      expect(settings.madhab, isNull);
      expect(settings.latitude, isNull);
      expect(settings.longitude, isNull);
      expect(settings.isComplete, isFalse);
    });

    test('testCalculationMethodParsing returns correct method strings', () {
      expect(CalculationMethods.parse(CalculationMethods.mwl), CalculationMethods.mwl);
      expect(CalculationMethods.parse(CalculationMethods.isna), CalculationMethods.isna);
      expect(
        CalculationMethods.parse(CalculationMethods.egyptian),
        CalculationMethods.egyptian,
      );
      expect(
        CalculationMethods.parse(CalculationMethods.ummAlQura),
        CalculationMethods.ummAlQura,
      );
      expect(
        CalculationMethods.parse(CalculationMethods.karachi),
        CalculationMethods.karachi,
      );
    });

    test('testCalculationMethodParsing unknown defaults to MWL', () {
      expect(CalculationMethods.parse('Unknown'), CalculationMethods.mwl);
      expect(CalculationMethods.parse(null), CalculationMethods.mwl);
    });

    test('fromFirestore alias matches fromMap', () {
      final map = {
        'onboardingComplete': true,
        'calculationMethod': CalculationMethods.karachi,
        'madhab': MadhabOptions.standard,
        'latitude': 30.0,
        'longitude': 31.0,
      };

      final fromFirestore = UserSettings.fromFirestore(map);
      final fromMap = UserSettings.fromMap(map);

      expect(fromFirestore.onboardingComplete, fromMap.onboardingComplete);
      expect(fromFirestore.calculationMethod, fromMap.calculationMethod);
      expect(fromFirestore.madhab, fromMap.madhab);
      expect(fromFirestore.latitude, fromMap.latitude);
      expect(fromFirestore.longitude, fromMap.longitude);
    });
  });
}
