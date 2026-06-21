import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class QiblaTestGeolocator extends GeolocatorPlatform {
  QiblaTestGeolocator({
    required this.permission,
    required this.locationEnabled,
    this.throwOnGetCurrentPosition = false,
    this.emitPositionStream = true,
    this.positionCompleter,
  });

  final LocationPermission permission;
  final bool locationEnabled;
  final bool throwOnGetCurrentPosition;
  final bool emitPositionStream;
  final Completer<Position>? positionCompleter;

  static final cairoPosition = Position(
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
    if (positionCompleter != null) {
      return positionCompleter!.future;
    }
    return cairoPosition;
  }

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) async* {
    if (!emitPositionStream) return;
    yield cairoPosition;
  }
}

void installCompassStreamMock({double heading = 135.0}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
    const EventChannel('hemanthraj/flutter_compass'),
    MockStreamHandler.inline(
      onListen: (arguments, events) {
        events.success(<double>[heading, 0.0, 0.0]);
      },
    ),
  );
}

void clearCompassStreamMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
    const EventChannel('hemanthraj/flutter_compass'),
    null,
  );
  FlutterQiblah().dispose();
}
