import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// OpenRouteService client for turn-by-turn routing (speed-limit based, no
/// live traffic). Free tier: 2,000 direction requests/day — sign up at
/// openrouteservice.org with email only (no credit card).
class OpenRouteService {
  OpenRouteService({http.Client? httpClient, String? apiKey})
      : _httpClient = httpClient ?? http.Client(),
        _apiKey = apiKey;

  final http.Client _httpClient;
  final String? _apiKey;

  String? get _orsKey {
    final injected = _apiKey?.trim();
    if (injected != null && injected.isNotEmpty) {
      return injected;
    }
    if (!dotenv.isInitialized) return null;
    final key = dotenv.env['ORS_API_KEY'] ?? '';
    return key.trim().isEmpty ? null : key.trim();
  }

  bool get isConfigured => _orsKey != null;

  /// Fetches a driving route between two points.
  /// ORS expects coordinates as [longitude, latitude].
  Future<RouteSummary?> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-car',
  }) async {
    final apiKey = _orsKey;
    if (apiKey == null) return null;

    final uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/$profile/json',
    );

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'coordinates': [
            [startLng, startLat],
            [endLng, endLat],
          ],
        }),
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final summary =
          (routes.first as Map<String, dynamic>)['summary'] as Map<String, dynamic>?;
      if (summary == null) return null;

      return RouteSummary(
        distanceMeters: (summary['distance'] as num).toDouble(),
        durationSeconds: (summary['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class RouteSummary {
  const RouteSummary({
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final double distanceMeters;
  final double durationSeconds;

  double get distanceKm => distanceMeters / 1000;

  int get durationMinutes => (durationSeconds / 60).round();

  String get formattedDuration {
    final totalMinutes = durationMinutes;
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${distanceMeters.round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
