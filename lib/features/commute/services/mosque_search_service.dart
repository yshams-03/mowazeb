import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/commute_result.dart';

class MosqueSearchService {
  MosqueSearchService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<MosqueResult>> findNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    int limit = 3,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
);
out center;
''';

    try {
      final response = await _httpClient.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
      );

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List<dynamic>? ?? [];

      final results = <MosqueResult>[];
      for (final element in elements) {
        final map = element as Map<String, dynamic>;
        final coords = _extractCoordinates(map);
        if (coords == null) continue;

        final tags = map['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String? ?? 'Mosque';
        final street = tags['addr:street'] as String? ?? '';
        final city = tags['addr:city'] as String? ?? '';
        final address = [street, city].where((s) => s.isNotEmpty).join(', ');

        final distance = _haversineMeters(
          latitude,
          longitude,
          coords.$1,
          coords.$2,
        );

        final type = map['type'] as String? ?? 'node';
        final id = map['id'] as int? ?? 0;

        results.add(
          MosqueResult(
            name: name,
            address: address.isNotEmpty ? address : 'Nearby mosque',
            distanceMeters: distance.round(),
            placeId: 'osm_${type}_$id',
            googleMapsUrl:
                'https://www.google.com/maps/dir/?api=1&destination=${coords.$1},${coords.$2}',
            latitude: coords.$1,
            longitude: coords.$2,
          ),
        );
      }

      results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return results.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  (double, double)? _extractCoordinates(Map<String, dynamic> element) {
    final lat = element['lat'] as num?;
    final lon = element['lon'] as num?;
    if (lat != null && lon != null) {
      return (lat.toDouble(), lon.toDouble());
    }

    final center = element['center'] as Map<String, dynamic>?;
    if (center != null) {
      final cLat = center['lat'] as num?;
      final cLon = center['lon'] as num?;
      if (cLat != null && cLon != null) {
        return (cLat.toDouble(), cLon.toDouble());
      }
    }
    return null;
  }

  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
