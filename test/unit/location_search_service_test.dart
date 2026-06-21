import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ummah_pulse/features/locations/services/location_search_service.dart';

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
  late LocationSearchService service;

  group('LocationSearchService.expandQuery', () {
    setUp(() {
      service = LocationSearchService();
    });

    test('testAbbreviationExpansion', () {
      expect(
        service.expandQuery('aast'),
        'Arab Academy for Science and Technology',
      );
      expect(service.expandQuery('alex'), 'Alexandria');
      expect(
        service.expandQuery('AAST'),
        contains('Arab Academy'),
      );
      expect(service.expandQuery('random'), 'random');
    });
  });

  group('LocationSearchService.search', () {
    test('testShortQueryReturnsEmpty', () async {
      var called = false;
      service = LocationSearchService(
        httpClient: _MockHttpClient((_) async {
          called = true;
          return http.Response('[]', 200);
        }),
        enableKnownPlaces: false,
        enableGeocodingFallback: false,
      );

      final results = await service.search('a');
      expect(results, isEmpty);
      expect(called, isFalse);
    });

    test('testSuccessfulSearchReturnsSuggestions', () async {
      final body = jsonEncode([
        {
          'display_name': 'Cairo Tower, Cairo, Egypt',
          'lat': '30.0459',
          'lon': '31.2243',
        },
        {
          'display_name': 'Cairo University, Giza, Egypt',
          'lat': '30.0276',
          'lon': '31.2104',
        },
      ]);

      service = LocationSearchService(
        httpClient: _MockHttpClient((_) async => http.Response(body, 200)),
        enableKnownPlaces: false,
        enableGeocodingFallback: false,
      );

      final results = await service.search('cairo tower');
      expect(results.length, 2);
      expect(results.first.shortName, 'Cairo Tower');
      expect(results.first.latitude, isA<double>());
      expect(results.first.longitude, isA<double>());
    });

    test('testNetworkErrorReturnsEmpty', () async {
      service = LocationSearchService(
        httpClient: _MockHttpClient((_) async => throw const SocketException('offline')),
        enableKnownPlaces: false,
        enableGeocodingFallback: false,
      );

      final results = await service.search('cairo tower');
      expect(results, isEmpty);
    });

    test('testNon200ResponseReturnsEmpty', () async {
      service = LocationSearchService(
        httpClient: _MockHttpClient((_) async => http.Response('error', 500)),
        enableKnownPlaces: false,
        enableGeocodingFallback: false,
      );

      final results = await service.search('cairo tower');
      expect(results, isEmpty);
    });

    test('testUserAgentHeaderIncluded', () async {
      String? userAgent;

      service = LocationSearchService(
        httpClient: _MockHttpClient((request) async {
          userAgent = request.headers['User-Agent'];
          return http.Response('[]', 200);
        }),
        enableKnownPlaces: false,
        enableGeocodingFallback: false,
      );

      await service.search('cairo');
      expect(userAgent, isNotNull);
      expect(userAgent, contains('mowazeb'));
    });

    test('knownMatches returns AAST without network', () {
      service = LocationSearchService();
      final matches = service.knownMatches('aast');
      expect(matches, isNotEmpty);
      expect(matches.first.shortName, 'AAST Alexandria');
    });
  });
}
