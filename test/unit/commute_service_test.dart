import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/services/commute_calculator.dart';
import 'package:ummah_pulse/features/commute/services/mosque_search_service.dart';
import 'package:ummah_pulse/features/locations/services/open_route_service.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);
  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('CommuteService', () {
    final now = DateTime(2026, 6, 21, 11, 0);
    final nextPrayer = PrayerTimeModel(
      name: PrayerName.dhuhr,
      time: DateTime(2026, 6, 21, 12, 30),
    );

    test('GREEN verdict when buffer >= 15 min and no mosques', () {
      const route = RouteSummary(distanceMeters: 5000, durationSeconds: 30 * 60);

      final result = computeCommuteResult(
        now: now,
        route: route,
        nextPrayer: nextPrayer,
      );

      expect(result.verdict, CommuteVerdict.green);
      expect(result.minutesBuffer, greaterThanOrEqualTo(15));
      expect(result.nearbyMosques, isEmpty);
    });

    test('RED verdict when buffer negative and mosques attached', () {
      const route = RouteSummary(distanceMeters: 20000, durationSeconds: 120 * 60);
      const mosques = [
        MosqueResult(
          name: 'Masjid Al-Noor',
          address: 'Main St',
          distanceMeters: 400,
          placeId: 'osm_node_1',
          googleMapsUrl:
              'https://www.google.com/maps/dir/?api=1&destination=30.0,31.0',
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
      expect(result.minutesBuffer, lessThan(0));
      expect(result.nearbyMosques.length, 1);
    });

    test('RED when prayer already passed', () {
      const route = RouteSummary(distanceMeters: 1000, durationSeconds: 5 * 60);
      final pastPrayer = PrayerTimeModel(
        name: PrayerName.fajr,
        time: DateTime(2026, 6, 21, 5, 0),
      );

      final result = computeCommuteResult(
        now: now,
        route: route,
        nextPrayer: pastPrayer,
      );

      expect(result.verdict, CommuteVerdict.red);
    });

    test('ORS API 403 returns null route', () async {
      final service = OpenRouteService(
        httpClient: _MockHttpClient((_) async => http.Response('Forbidden', 403)),
        apiKey: 'test-key',
      );

      final route = await service.getDirections(
        startLat: 30.0,
        startLng: 31.0,
        endLat: 31.0,
        endLng: 32.0,
      );

      expect(route, isNull);
    });

    test('network error returns null route', () async {
      final service = OpenRouteService(
        httpClient: _MockHttpClient((_) async => throw const SocketException('offline')),
        apiKey: 'test-key',
      );

      final route = await service.getDirections(
        startLat: 30.0,
        startLng: 31.0,
        endLat: 31.0,
        endLng: 32.0,
      );

      expect(route, isNull);
    });

    test('mosque search limits to top 3', () async {
      final elements = List.generate(
        5,
        (i) => {
          'type': 'node',
          'id': i,
          'lat': 30.04 + i * 0.001,
          'lon': 31.23,
          'tags': {'name': 'Mosque $i', 'religion': 'muslim', 'amenity': 'place_of_worship'},
        },
      );

      final service = MosqueSearchService(
        httpClient: _MockHttpClient(
          (_) async => http.Response(jsonEncode({'elements': elements}), 200),
        ),
      );

      final results = await service.findNearbyMosques(
        latitude: 30.0444,
        longitude: 31.2357,
      );

      expect(results.length, 3);
    });

    test('Google Maps URL contains coordinates', () async {
      final service = MosqueSearchService(
        httpClient: _MockHttpClient(
          (_) async => http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'id': 1,
                  'lat': 30.05,
                  'lon': 31.24,
                  'tags': {'name': 'Test Mosque'},
                },
              ],
            }),
            200,
          ),
        ),
      );

      final results = await service.findNearbyMosques(
        latitude: 30.0444,
        longitude: 31.2357,
      );

      expect(results.first.googleMapsUrl, contains('destination=30.05,31.24'));
    });
  });
}
