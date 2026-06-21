import 'package:flutter_test/flutter_test.dart';

import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/services/commute_calculator.dart';
import 'package:ummah_pulse/features/locations/services/open_route_service.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

void main() {
  group('computeCommuteResult', () {
    final now = DateTime(2026, 6, 21, 11, 0);
    final nextPrayer = PrayerTimeModel(
      name: PrayerName.dhuhr,
      time: DateTime(2026, 6, 21, 12, 30),
    );

    test('GREEN when drive time is within next-prayer countdown', () {
      const route = RouteSummary(distanceMeters: 5000, durationSeconds: 30 * 60);

      final result = computeCommuteResult(
        now: now,
        route: route,
        nextPrayer: nextPrayer,
      );

      expect(result.verdict, CommuteVerdict.green);
      expect(result.minutesUntilPrayer, 90);
      expect(result.drivingDurationMinutes, 30);
      expect(result.minutesBuffer, 60);
      expect(result.nearbyMosques, isEmpty);
    });

    test('GREEN when drive time exactly equals countdown', () {
      const route = RouteSummary(distanceMeters: 8000, durationSeconds: 90 * 60);

      final result = computeCommuteResult(
        now: now,
        route: route,
        nextPrayer: nextPrayer,
      );

      expect(result.verdict, CommuteVerdict.green);
      expect(result.minutesBuffer, 0);
    });

    test('RED when drive time exceeds next-prayer countdown', () {
      const route = RouteSummary(distanceMeters: 20000, durationSeconds: 91 * 60);
      const mosques = [
        MosqueResult(
          name: 'Masjid Al-Noor',
          address: 'Main St',
          distanceMeters: 400,
          placeId: 'osm_node_1',
          googleMapsUrl: 'https://maps.example',
          latitude: 30.0,
          longitude: 31.0,
        ),
      ];

      final result = computeCommuteResult(
        now: now,
        route: route,
        nextPrayer: nextPrayer,
        nearbyMosques: mosques,
      );

      expect(result.verdict, CommuteVerdict.red);
      expect(result.minutesUntilPrayer, 90);
      expect(result.drivingDurationMinutes, greaterThan(90));
      expect(result.minutesBuffer, lessThan(0));
      expect(result.nearbyMosques.length, 1);
    });
  });
}
