import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../models/location_suggestion.dart';

class LocationSearchException implements Exception {
  LocationSearchException(this.message);
  final String message;
}

class LocationSearchService {
  LocationSearchService({
    http.Client? httpClient,
    this.enableKnownPlaces = true,
    this.enableGeocodingFallback = true,
  }) : _httpClient = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 12);

  final http.Client _httpClient;
  final bool enableKnownPlaces;
  final bool enableGeocodingFallback;

  static const Map<String, String> abbreviations = {
    'aast alexandria': 'Arab Academy for Science and Technology Alexandria',
    'aast alex': 'Arab Academy for Science and Technology Alexandria',
    'aast': 'Arab Academy for Science and Technology',
    'alex': 'Alexandria',
    'cairo': 'Cairo',
    'giza': 'Giza',
    'cu': 'Cairo University',
    'ain': 'Ain Shams University',
  };

  static const Map<String, LocationSuggestion> knownPlaces = {
    'aast': LocationSuggestion(
      displayName:
          'Arab Academy for Science and Technology, Abu Qir, Alexandria, Egypt',
      shortName: 'AAST Alexandria',
      address:
          'Arab Academy for Science and Technology, Abu Qir, Alexandria, Egypt',
      latitude: 31.3069,
      longitude: 30.0606,
    ),
    'arab academy': LocationSuggestion(
      displayName:
          'Arab Academy for Science and Technology, Abu Qir, Alexandria, Egypt',
      shortName: 'AAST Alexandria',
      address:
          'Arab Academy for Science and Technology, Abu Qir, Alexandria, Egypt',
      latitude: 31.3069,
      longitude: 30.0606,
    ),
    'cairo university': LocationSuggestion(
      displayName: 'Cairo University, Giza, Egypt',
      shortName: 'Cairo University',
      address: 'Cairo University, Giza, Egypt',
      latitude: 30.0276,
      longitude: 31.2104,
    ),
    'ain shams': LocationSuggestion(
      displayName: 'Ain Shams University, Cairo, Egypt',
      shortName: 'Ain Shams University',
      address: 'Ain Shams University, Cairo, Egypt',
      latitude: 30.0778,
      longitude: 31.2859,
    ),
  };

  String expandQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final lower = trimmed.toLowerCase();
    final sorted = abbreviations.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sorted) {
      if (lower == entry.key || lower.startsWith('${entry.key} ')) {
        return trimmed.replaceFirst(
          RegExp(entry.key, caseSensitive: false),
          entry.value,
        );
      }
    }
    return trimmed;
  }

  List<LocationSuggestion> knownMatches(String query) {
    if (!enableKnownPlaces) return [];

    final lower = query.toLowerCase().trim();
    final expanded = expandQuery(query).toLowerCase();
    final seen = <String>{};
    final results = <LocationSuggestion>[];

    for (final entry in knownPlaces.entries) {
      if (lower.contains(entry.key) || expanded.contains(entry.key)) {
        final key = '${entry.value.latitude}:${entry.value.longitude}';
        if (seen.add(key)) {
          results.add(entry.value);
        }
      }
    }
    return results;
  }

  Future<List<LocationSuggestion>> search(
    String query, {
    double? biasLat,
    double? biasLng,
    String? nearCity,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final expanded = expandQuery(trimmed);
    final known = knownMatches(trimmed);

    List<LocationSuggestion> online = const [];
    try {
      online = await _searchNominatim(
        expanded,
        biasLat: biasLat,
        biasLng: biasLng,
      );
    } on LocationSearchException {
      if (!enableGeocodingFallback && !enableKnownPlaces) {
        return [];
      }
    } on SocketException {
      if (!enableGeocodingFallback && !enableKnownPlaces) {
        return [];
      }
    } catch (_) {
      if (!enableGeocodingFallback && !enableKnownPlaces) {
        return [];
      }
    }

    if (online.isEmpty && enableGeocodingFallback) {
      online = await _searchGeocoding(
        expanded,
        nearCity: nearCity,
        rawQuery: trimmed,
      );
    }

    final merged = <LocationSuggestion>[...known];
    final seen = merged
        .map(
          (s) =>
              '${s.latitude.toStringAsFixed(4)}:${s.longitude.toStringAsFixed(4)}',
        )
        .toSet();

    for (final item in online) {
      final key =
          '${item.latitude.toStringAsFixed(4)}:${item.longitude.toStringAsFixed(4)}';
      if (seen.add(key)) {
        merged.add(item);
      }
    }

    return merged.take(8).toList();
  }

  Future<List<LocationSuggestion>> _searchNominatim(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final params = <String, String>{
      'q': query,
      'format': 'json',
      'limit': '6',
      'addressdetails': '1',
      'countrycodes': 'eg',
    };

    if (biasLat != null && biasLng != null) {
      params['viewbox'] =
          '${biasLng - 0.5},${biasLat + 0.5},${biasLng + 0.5},${biasLat - 0.5}';
      params['bounded'] = '0';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    final response = await _httpClient
        .get(
          uri,
          headers: const {
            'User-Agent': 'mowazeb/1.0 (contact@mowazeb.app)',
            'Accept-Language': 'en',
          },
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw LocationSearchException(
        'Online search failed (${response.statusCode}).',
      );
    }

    final body = response.body.trim();
    if (!body.startsWith('[')) {
      throw LocationSearchException('Online search temporarily unavailable.');
    }

    final json = jsonDecode(body) as List<dynamic>;
    return json
        .map(
          (item) => LocationSuggestion.fromNominatim(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<LocationSuggestion>> _searchGeocoding(
    String query, {
    String? nearCity,
    required String rawQuery,
  }) async {
    final attempts = <String>{
      query,
      if (nearCity != null && nearCity.isNotEmpty) '$query, $nearCity, Egypt',
      '$query, Egypt',
      rawQuery,
      if (nearCity != null && nearCity.isNotEmpty) '$rawQuery, $nearCity, Egypt',
    };

    final results = <LocationSuggestion>[];
    final seen = <String>{};

    for (final attempt in attempts) {
      if (attempt.trim().length < 2) continue;

      try {
        final locations = await locationFromAddress(attempt);
        for (final location in locations.take(4)) {
          final key =
              '${location.latitude.toStringAsFixed(4)}:${location.longitude.toStringAsFixed(4)}';
          if (!seen.add(key)) continue;

          results.add(
            LocationSuggestion(
              displayName: attempt,
              shortName: attempt.split(',').first.trim(),
              address: attempt,
              latitude: location.latitude,
              longitude: location.longitude,
            ),
          );
        }
        if (results.isNotEmpty) break;
      } catch (_) {
        continue;
      }
    }

    return results;
  }
}
