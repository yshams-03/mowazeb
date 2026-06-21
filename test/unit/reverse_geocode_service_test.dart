import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ummah_pulse/features/locations/services/reverse_geocode_service.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

void main() {
  group('ReverseGeocodeService', () {
    test('returns MapPickerResult from ORS response', () async {
      final client = _FakeHttpClient((request) async {
        expect(request.url.host, 'api.openrouteservice.org');
        return http.Response(
          '''
{
  "features": [{
    "properties": {
      "label": "AAST, Abu Qir, Alexandria, Egypt",
      "name": "Arab Academy for Science and Technology"
    }
  }]
}
''',
          200,
        );
      });

      final service = ReverseGeocodeService(httpClient: client, apiKey: 'test-key');
      final result = await service.reverseGeocode(31.3069, 30.0606);

      expect(result, isNotNull);
      expect(result!.shortName, 'Arab Academy for Science and Technology');
      expect(result.address, 'AAST, Abu Qir, Alexandria, Egypt');
    });

    test('falls back to Nominatim when ORS key is missing', () async {
      final client = _FakeHttpClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        return http.Response(
          '''
{
  "display_name": "Cairo, Cairo Governorate, Egypt",
  "name": "Cairo"
}
''',
          200,
        );
      });

      final service = ReverseGeocodeService(httpClient: client);
      final result = await service.reverseGeocode(30.0444, 31.2357);

      expect(result!.shortName, 'Cairo');
      expect(result.address, 'Cairo, Cairo Governorate, Egypt');
    });

    test('returns null on non-200 response', () async {
      final client = _FakeHttpClient((_) async => http.Response('', 500));

      final service = ReverseGeocodeService(httpClient: client);
      final result = await service.reverseGeocode(30.0, 31.0);
      expect(result, isNull);
    });

    test('uses first address segment when ORS has no name', () async {
      final client = _FakeHttpClient((_) async {
        return http.Response(
          '''
{
  "features": [{
    "properties": {
      "label": "Cairo, Cairo Governorate, Egypt"
    }
  }]
}
''',
          200,
        );
      });

      final service = ReverseGeocodeService(httpClient: client, apiKey: 'test-key');
      final result = await service.reverseGeocode(30.0444, 31.2357);

      expect(result!.shortName, 'Cairo');
    });
  });
}
