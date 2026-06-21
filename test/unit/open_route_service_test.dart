import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ummah_pulse/features/locations/services/open_route_service.dart';

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
  group('OpenRouteService', () {
    test('returns RouteSummary on success', () async {
      final client = _FakeHttpClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          contains('/v2/directions/driving-car/json'),
        );
        return http.Response(
          '''
{
  "routes": [{
    "summary": {
      "distance": 5200.0,
      "duration": 720.0
    }
  }]
}
''',
          200,
        );
      });

      final service = OpenRouteService(httpClient: client, apiKey: 'test-key');
      final result = await service.getDirections(
        startLat: 30.0444,
        startLng: 31.2357,
        endLat: 31.3069,
        endLng: 30.0606,
      );

      expect(result, isNotNull);
      expect(result!.distanceMeters, 5200);
      expect(result.durationMinutes, 12);
      expect(result.formattedDistance, '5.2 km');
      expect(result.formattedDuration, '12 min');
    });

    test('returns null when API key is missing', () async {
      final service = OpenRouteService(httpClient: _FakeHttpClient((_) async {
        throw StateError('Should not call HTTP without API key');
      }));

      final result = await service.getDirections(
        startLat: 30.0,
        startLng: 31.0,
        endLat: 31.0,
        endLng: 32.0,
      );
      expect(result, isNull);
      expect(service.isConfigured, isFalse);
    });

    test('returns null on non-200 response', () async {
      final client = _FakeHttpClient((_) async => http.Response('', 500));
      final service = OpenRouteService(httpClient: client, apiKey: 'test-key');

      final result = await service.getDirections(
        startLat: 30.0,
        startLng: 31.0,
        endLat: 31.0,
        endLng: 32.0,
      );
      expect(result, isNull);
    });
  });
}
