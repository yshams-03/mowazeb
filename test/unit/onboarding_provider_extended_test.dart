import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ummah_pulse/features/onboarding/providers/onboarding_provider.dart';

import '../helpers/qibla_test_helpers.dart';

void main() {
  group('OnboardingController requestLocation', () {
    late GeolocatorPlatform originalGeolocator;
    late FakeFirebaseFirestore firestore;
    late OnboardingController controller;

    setUp(() {
      originalGeolocator = GeolocatorPlatform.instance;
      firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-onboard-loc'),
        signedIn: true,
      );
      controller = OnboardingController(firestore, auth);
    });

    tearDown(() {
      GeolocatorPlatform.instance = originalGeolocator;
    });

    test('sets coordinates when permission granted', () async {
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: true,
      );

      await controller.requestLocation();

      expect(controller.state.locationGranted, isTrue);
      expect(controller.state.latitude, QiblaTestGeolocator.cairoPosition.latitude);
      expect(controller.state.longitude, QiblaTestGeolocator.cairoPosition.longitude);
      expect(controller.state.error, isNull);
    });

    test('sets error when location services disabled', () async {
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.whileInUse,
        locationEnabled: false,
      );

      await controller.requestLocation();

      expect(controller.state.locationGranted, isFalse);
      expect(
        controller.state.error,
        contains('Location services are disabled'),
      );
    });

    test('sets error when permission denied forever', () async {
      GeolocatorPlatform.instance = QiblaTestGeolocator(
        permission: LocationPermission.deniedForever,
        locationEnabled: true,
      );

      await controller.requestLocation();

      expect(controller.state.locationGranted, isFalse);
      expect(
        controller.state.error,
        contains('permanently denied'),
      );
    });

    test('canProceedFromLocation requires grant and coordinates', () {
      expect(controller.state.canProceedFromLocation, isFalse);

      controller.state = controller.state.copyWith(
        locationGranted: true,
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(controller.state.canProceedFromLocation, isTrue);
    });
  });
}
