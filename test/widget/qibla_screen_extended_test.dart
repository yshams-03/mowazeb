import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/qibla/screens/qibla_screen.dart';

import '../helpers/qibla_test_helpers.dart';
import '../helpers/test_helpers.dart';

Future<void> _pumpQibla(WidgetTester tester) async {
  setLargeScreen(tester);
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

Future<void> _settlePrepare(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('QiblaScreen extended', () {
    late GeolocatorPlatform originalGeolocator;

    setUp(() {
      originalGeolocator = GeolocatorPlatform.instance;
      FlutterQiblah().dispose();
    });

    tearDown(() {
      GeolocatorPlatform.instance = originalGeolocator;
      clearCompassStreamMock();
    });

    testWidgets('shows loading indicator before prepare completes', (tester) async {
      final positionCompleter = Completer<Position>();
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
        positionCompleter: positionCompleter,
      );
      await _pumpQibla(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      positionCompleter.complete(QiblaTestGeolocator.cairoPosition);
      await _settlePrepare(tester, rounds: 5);
    });

    testWidgets('shows permission error when location is denied', (tester) async {
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.denied,
        locationEnabled: true,
      );
      await _pumpQibla(tester);
      await _settlePrepare(tester);

      expect(
        find.text('Location permission is required for Qibla direction.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('shows compass UI with degrees and distance when stream emits', (
      tester,
    ) async {
      installCompassStreamMock(heading: 200.5);
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
      );

      await _pumpQibla(tester);
      await _settlePrepare(tester, rounds: 20);

      expect(find.byType(Transform), findsWidgets);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(find.textContaining('km to Mecca'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d')), findsWidgets);
    });

    testWidgets('shows sensor error when stream has no data', (tester) async {
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
        emitPositionStream: false,
      );
      installCompassStreamMock(heading: 0);

      await _pumpQibla(tester);
      await _settlePrepare(tester, rounds: 20);

      expect(
        find.text('Compass sensor not available on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('disposes without stream subscription errors', (tester) async {
      installCompassStreamMock();
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
      );

      await _pumpQibla(tester);
      await _settlePrepare(tester, rounds: 10);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
