import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/onboarding/providers/onboarding_provider.dart';
import 'package:ummah_pulse/features/onboarding/screens/onboarding_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    setLargeScreen(tester);
    await tester.pumpWidget(
      buildTestApp(child: const OnboardingScreen()),
    );
    await tester.pump();
  }

  void setStep(WidgetTester tester, OnboardingState state) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
    container.read(onboardingControllerProvider.notifier).state = state;
  }

  group('OnboardingScreen', () {
    testWidgets('testOnboardingStep1ShowsLocationUI', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('Find Your Location'), findsOneWidget);
      expect(find.textContaining('location'), findsWidgets);
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('testOnboardingStep2ShowsCalculationMethods', (tester) async {
      await pumpOnboarding(tester);
      setStep(
        tester,
        const OnboardingState(
          currentStep: 1,
          locationGranted: true,
          latitude: testLatitude,
          longitude: testLongitude,
        ),
      );
      await tester.pump();

      for (final method in CalculationMethods.all) {
        expect(find.text(method), findsOneWidget);
      }
    });

    testWidgets('testOnboardingStep3ShowsMadhabs', (tester) async {
      await pumpOnboarding(tester);
      setStep(tester, const OnboardingState(currentStep: 2));
      await tester.pump();

      expect(find.text(MadhabOptions.standard), findsOneWidget);
      expect(find.text(MadhabOptions.hanafi), findsOneWidget);
    });

    testWidgets('testOnboardingProgressIndicator reflects current step',
        (tester) async {
      await pumpOnboarding(tester);

      var activeBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == AppColors.primaryGreen,
      );
      expect(activeBars, findsNWidgets(1));

      setStep(
        tester,
        const OnboardingState(
          currentStep: 1,
          locationGranted: true,
          latitude: testLatitude,
          longitude: testLongitude,
        ),
      );
      await tester.pump();
      activeBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == AppColors.primaryGreen,
      );
      expect(activeBars, findsNWidgets(2));

      setStep(tester, const OnboardingState(currentStep: 2));
      await tester.pump();
      activeBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == AppColors.primaryGreen,
      );
      expect(activeBars, findsNWidgets(3));
    });
  });
}
