import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';

void main() {
  group('CommuteVerdict', () {
    test('isSafe is true only for green', () {
      expect(CommuteVerdict.green.isSafe, isTrue);
      expect(CommuteVerdict.red.isSafe, isFalse);
    });
  });

  group('MosqueResult', () {
    test('formattedDistance shows meters under 1 km', () {
      const mosque = MosqueResult(
        name: 'Masjid',
        address: 'Main St',
        distanceMeters: 450,
        placeId: 'node-1',
        googleMapsUrl: 'https://maps.example',
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(mosque.formattedDistance, '450 m');
    });

    test('formattedDistance shows km at or above 1 km', () {
      const mosque = MosqueResult(
        name: 'Masjid',
        address: 'Main St',
        distanceMeters: 1500,
        placeId: 'node-2',
        googleMapsUrl: 'https://maps.example',
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(mosque.formattedDistance, '1.5 km');
    });
  });

  group('CommuteResult', () {
    test('stores next prayer name and buffer', () {
      final now = DateTime(2026, 6, 21, 11, 0);
      final result = CommuteResult(
        estimatedArrival: now.add(const Duration(minutes: 25)),
        drivingDurationMinutes: 25,
        minutesUntilPrayer: 60,
        nextPrayerName: 'Dhuhr',
        nextPrayerTime: now.add(const Duration(minutes: 60)),
        minutesBuffer: 35,
        verdict: CommuteVerdict.green,
      );

      expect(result.nextPrayerName, 'Dhuhr');
      expect(result.minutesBuffer, 35);
      expect(result.verdict, CommuteVerdict.green);
    });
  });
}
