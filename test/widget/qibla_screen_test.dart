import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/qibla/screens/qibla_screen.dart';

import '../helpers/test_helpers.dart';

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  _FakeGeolocatorPlatform({
    required this.permission,
    required this.locationEnabled,
    this.throwOnGetCurrentPosition = false,
  });

  final LocationPermission permission;
  final bool locationEnabled;
  final bool throwOnGetCurrentPosition;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<bool> isLocationServiceEnabled() async => locationEnabled;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (throwOnGetCurrentPosition) {
      throw Exception('Location lookup failed');
    }

    return Position(
      longitude: 31.2357,
      latitude: 30.0444,
      timestamp: DateTime(2026, 6, 21),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

Future<void> _pumpQiblaScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        userSettingsProvider.overrideWith(
          (ref) => Stream.value(cairoSettings()),
        ),
      ],
      child: const QiblaScreen(),
    ),
  );
}

Future<void> _settlePrepare(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('QiblaScreen', () {
    late GeolocatorPlatform originalGeolocator;

    setUp(() {
      originalGeolocator = GeolocatorPlatform.instance;
    });

    tearDown(() {
      GeolocatorPlatform.instance = originalGeolocator;
    });

    testWidgets('shows Qibla Direction header', (tester) async {
      setLargeScreen(tester);
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        permission: LocationPermission.denied,
        locationEnabled: false,
      );
      await _pumpQiblaScreen(tester);
      await tester.pump();

      expect(find.text('Qibla Direction'), findsOneWidget);
    });

    testWidgets('shows location required error when location is disabled', (
      tester,
    ) async {
      setLargeScreen(tester);
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        permission: LocationPermission.whileInUse,
        locationEnabled: false,
      );
      await _pumpQiblaScreen(tester);
      await _settlePrepare(tester);

      expect(
        find.text('Location permission is required for Qibla direction.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('shows sensor error when current position lookup fails', (
      tester,
    ) async {
      setLargeScreen(tester);
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
        throwOnGetCurrentPosition: true,
      );
      await _pumpQiblaScreen(tester);
      await _settlePrepare(tester);

      expect(
        find.text('Compass sensor not available on this device.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });
  });
}
