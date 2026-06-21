import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/map_picker_result.dart';

/// Reverse geocoding via OpenRouteService, with Nominatim fallback when no
/// ORS token is configured.
class ReverseGeocodeService {
  ReverseGeocodeService({http.Client? httpClient, String? apiKey})
      : _httpClient = httpClient ?? http.Client(),
        _apiKey = apiKey;

  static const _userAgent = 'mowazeb/1.0 (contact@mowazeb.app)';

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

  Future<MapPickerResult?> reverseGeocode(double lat, double lng) async {
    final orsKey = _orsKey;
    if (orsKey != null) {
      final orsResult = await _reverseGeocodeOrs(lat, lng, orsKey);
      if (orsResult != null) return orsResult;
    }
    return _reverseGeocodeNominatim(lat, lng);
  }

  Future<MapPickerResult?> _reverseGeocodeOrs(
    double lat,
    double lng,
    String apiKey,
  ) async {
    final uri = Uri.https(
      'api.openrouteservice.org',
      '/geocode/reverse',
      {
        'point.lat': lat.toString(),
        'point.lon': lng.toString(),
        'size': '1',
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {'Authorization': apiKey},
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;

      final feature = features.first as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final label = properties['label'] as String? ?? '';
      if (label.isEmpty) return null;

      final name = properties['name'] as String?;
      final shortName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : label.split(',').first.trim();

      return MapPickerResult(
        latitude: lat,
        longitude: lng,
        address: label,
        shortName: shortName.isNotEmpty ? shortName : label,
      );
    } catch (_) {
      return null;
    }
  }

  Future<MapPickerResult?> _reverseGeocodeNominatim(double lat, double lng) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = json['display_name'] as String? ?? '';
      if (displayName.isEmpty) return null;

      var shortName = displayName.split(',').first.trim();
      final named = json['name'] as String?;
      if (named != null && named.trim().isNotEmpty) {
        shortName = named.trim();
      }

      return MapPickerResult(
        latitude: lat,
        longitude: lng,
        address: displayName,
        shortName: shortName,
      );
    } catch (_) {
      return null;
    }
  }
}
