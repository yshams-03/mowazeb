import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('OnboardingController', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late OnboardingController controller;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-onboard'), signedIn: true);
      controller = OnboardingController(firestore, auth);
    });

    test('starts at step 0 with default settings', () {
      expect(controller.state.currentStep, 0);
      expect(controller.state.calculationMethod, CalculationMethods.mwl);
      expect(controller.state.madhab, MadhabOptions.standard);
      expect(controller.state.isSaving, isFalse);
    });

    test('setCalculationMethod updates method', () {
      controller.setCalculationMethod(CalculationMethods.egyptian);
      expect(controller.state.calculationMethod, CalculationMethods.egyptian);
    });

    test('setMadhab updates madhab', () {
      controller.setMadhab(MadhabOptions.hanafi);
      expect(controller.state.madhab, MadhabOptions.hanafi);
    });

    test('nextStep advances up to step 2', () {
      controller.nextStep();
      expect(controller.state.currentStep, 1);

      controller.nextStep();
      expect(controller.state.currentStep, 2);

      controller.nextStep();
      expect(controller.state.currentStep, 2);
    });

    test('previousStep retreats down to step 0', () {
      controller.nextStep();
      controller.nextStep();
      expect(controller.state.currentStep, 2);

      controller.previousStep();
      expect(controller.state.currentStep, 1);

      controller.previousStep();
      expect(controller.state.currentStep, 0);

      controller.previousStep();
      expect(controller.state.currentStep, 0);
    });

    test('completeOnboarding writes preferences to Firestore', () async {
      controller.setCalculationMethod(CalculationMethods.egyptian);
      controller.setMadhab(MadhabOptions.hanafi);
      controller.state = controller.state.copyWith(
        latitude: 30.0444,
        longitude: 31.2357,
        locationLabel: 'Cairo',
      );

      final success = await controller.completeOnboarding();

      expect(success, isTrue);
      expect(controller.state.isSaving, isFalse);
      expect(controller.state.error, isNull);

      final doc = await firestore
          .doc(FirestorePaths.userSettings('uid-onboard'))
          .get();
      expect(doc.exists, isTrue);

      final settings = UserSettings.fromFirestore(doc.data());
      expect(settings.onboardingComplete, isTrue);
      expect(settings.calculationMethod, CalculationMethods.egyptian);
      expect(settings.madhab, MadhabOptions.hanafi);
      expect(settings.latitude, 30.0444);
      expect(settings.longitude, 31.2357);
      expect(settings.locationLabel, 'Cairo');
    });

    test('completeOnboarding returns false when not signed in', () async {
      final guestAuth = MockFirebaseAuth(signedIn: false);
      final guestController = OnboardingController(firestore, guestAuth);

      final success = await guestController.completeOnboarding();

      expect(success, isFalse);
    });
  });
}
