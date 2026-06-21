import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_constants.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_service.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_sync_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_cache_service.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

http.Response _utf8Response(String body, int statusCode) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  const sampleBody = '''
{
  "code": 200,
  "data": {
    "timings": {
      "Fajr": "04:32",
      "Sunrise": "06:01",
      "Dhuhr": "12:18",
      "Asr": "15:38",
      "Maghrib": "18:35",
      "Isha": "20:04"
    },
    "date": {
      "hijri": {
        "date": "25-12-1447",
        "month": { "number": 12, "en": "Dhū al-Ḥijjah", "ar": "ذو الحجة" },
        "year": "1447",
        "day": "25"
      }
    },
    "meta": { "timezone": "Africa/Cairo" }
  }
}
''';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AlAdhanService.fetchTimings', () {
    test('returns all five prayers and ignores Sunrise', () async {
      final service = AlAdhanService(
        client: _FakeClient((_) async => _utf8Response(sampleBody, 200)),
      );

      final result = await service.fetchTimings(
        latitude: 30.0444,
        longitude: 31.2357,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
        date: DateTime(2026, 6, 21),
      );

      expect(result, isNotNull);
      expect(result!.prayers.length, 5);
      expect(
        result.prayers.map((p) => p.name),
        containsAll(PrayerName.values),
      );
    });

    test('parses hijri date fields', () async {
      final service = AlAdhanService(
        client: _FakeClient((_) async => _utf8Response(sampleBody, 200)),
      );

      final result = await service.fetchTimings(
        latitude: 30.0444,
        longitude: 31.2357,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );

      expect(result!.hijri?.day, 25);
      expect(result.hijri?.monthNum, 12);
      expect(result.hijri?.monthEn, 'Dhū al-Ḥijjah');
      expect(result.hijri?.monthAr, 'ذو الحجة');
      expect(result.hijri?.year, 1447);
    });

    test('method and school appear in request URL', () async {
      http.BaseRequest? captured;
      final service = AlAdhanService(
        client: _FakeClient((request) async {
          captured = request;
          return _utf8Response(sampleBody, 200);
        }),
      );

      await service.fetchTimings(
        latitude: 30,
        longitude: 31,
        calculationMethod: CalculationMethods.karachi,
        madhab: MadhabOptions.hanafi,
      );

      expect(captured!.url.queryParameters['method'], '1');
      expect(captured!.url.queryParameters['school'], '1');
    });

    test('uses unix timestamp path segment', () async {
      http.BaseRequest? captured;
      final service = AlAdhanService(
        client: _FakeClient((request) async {
          captured = request;
          return _utf8Response(sampleBody, 200);
        }),
      );

      final date = DateTime(2026, 6, 21);
      await service.fetchTimings(
        latitude: 30,
        longitude: 31,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
        date: date,
      );

      final expected = AlAdhanConstants.unixTimestampForDate(date).toString();
      expect(captured!.url.pathSegments.last, expected);
    });

    test('network failure returns null', () async {
      final service = AlAdhanService(
        client: _FakeClient((_) async => throw const SocketException('offline')),
      );

      final result = await service.fetchTimings(
        latitude: 30,
        longitude: 31,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );

      expect(result, isNull);
    });
  });

  group('AlAdhanSyncService.getHijriDate', () {
    test('falls back to hijri package when cache empty', () async {
      final hijri = await AlAdhanSyncService.getHijriDate();
      expect(hijri.day, inInclusiveRange(1, 30));
      expect(hijri.monthNum, inInclusiveRange(1, 12));
      expect(hijri.year, greaterThan(1440));
    });

    test('reads hijri from SharedPreferences cache', () async {
      final service = AlAdhanService(
        client: _FakeClient((_) async => _utf8Response(sampleBody, 200)),
      );
      final result = await service.fetchTimings(
        latitude: 30.0444,
        longitude: 31.2357,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );
      await PrayerCacheService.instance.saveHijriDate(result!.hijri!);

      final loaded = await AlAdhanSyncService.getHijriDate();
      expect(loaded.day, 25);
      expect(loaded.monthEn, 'Dhū al-Ḥijjah');
    });
  });
}
