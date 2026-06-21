import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_service.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_sync_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_cache_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

http.Response _utf8Response(String body, int statusCode) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

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

void main() {
  const sampleBody = '''
{
  "code": 200,
  "data": {
    "timings": {
      "Fajr": "04:32",
      "Dhuhr": "12:18",
      "Asr": "15:38",
      "Maghrib": "18:35",
      "Isha": "20:04"
    },
    "date": {
      "hijri": {
        "month": { "number": 12, "en": "Dhul Hijjah", "ar": "ذو الحجة" },
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

  group('AlAdhanSyncService.syncIfNeeded', () {
    test('skips when already synced today', () async {
      final today = PrayerCalculator.dateKeyFor(DateTime.now());
      await PrayerCacheService.instance.markSynced(today);

      var httpCalls = 0;
      final service = AlAdhanSyncService(
        aladhan: AlAdhanService(
          client: _FakeClient((_) async {
            httpCalls++;
            return _utf8Response(sampleBody, 200);
          }),
        ),
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'uid'), signedIn: true),
      );

      final prayers = PrayerCalculator.calculateFromSettings(cairoSettings());
      await service.syncIfNeeded(
        cairoSettings(),
        localPrayers: prayers,
      );

      expect(httpCalls, 0);
    });

    test('successful sync stores hijri and marks synced', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-sync'), signedIn: true);

      final service = AlAdhanSyncService(
        aladhan: AlAdhanService(
          client: _FakeClient((_) async => _utf8Response(sampleBody, 200)),
        ),
        firestore: firestore,
        auth: auth,
      );

      final settings = cairoSettings();
      final prayers = PrayerCalculator.calculateFromSettings(settings);

      await service.syncIfNeeded(settings, localPrayers: prayers);

      final hijri = await PrayerCacheService.instance.loadHijriDate();
      expect(hijri?.day, 25);
      expect(hijri?.monthEn, 'Dhul Hijjah');

      final lastSync = await PrayerCacheService.instance.lastSyncDateKey();
      expect(lastSync, PrayerCalculator.dateKeyFor(DateTime.now()));
    });

    test('network failure does not mark synced', () async {
      final service = AlAdhanSyncService(
        aladhan: AlAdhanService(
          client: _FakeClient((_) async => throw const SocketException('offline')),
        ),
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'uid'), signedIn: true),
      );

      await service.syncIfNeeded(
        cairoSettings(),
        localPrayers: PrayerCalculator.calculateFromSettings(cairoSettings()),
      );

      final lastSync = await PrayerCacheService.instance.lastSyncDateKey();
      expect(lastSync, isNull);
    });

    test('fails silently without throwing', () async {
      final service = AlAdhanSyncService(
        aladhan: AlAdhanService(
          client: _FakeClient((_) async => _utf8Response('bad', 500)),
        ),
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(mockUser: MockUser(uid: 'uid'), signedIn: true),
      );

      await expectLater(
        service.syncIfNeeded(
          cairoSettings(),
          localPrayers: PrayerCalculator.calculateFromSettings(cairoSettings()),
        ),
        completes,
      );
    });
  });
}
