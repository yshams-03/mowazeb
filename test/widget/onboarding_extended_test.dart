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
    await tester.pumpWidget(buildTestApp(child: const OnboardingScreen()));
    await tester.pump();
  }

  void setStep(WidgetTester tester, OnboardingState state) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
    container.read(onboardingControllerProvider.notifier).state = state;
  }

  group('OnboardingScreen extended', () {
    testWidgets('step 1 hides back button', (tester) async {
      await pumpOnboarding(tester);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('step 2 shows back button', (tester) async {
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

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calculation method selection persists when returning', (tester) async {
      await pumpOnboarding(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)),
      );
      final controller = container.read(onboardingControllerProvider.notifier);

      setStep(
        tester,
        const OnboardingState(
          currentStep: 1,
          locationGranted: true,
          latitude: testLatitude,
          longitude: testLongitude,
          calculationMethod: CalculationMethods.isna,
        ),
      );
      await tester.pump();

      expect(find.text(CalculationMethods.isna), findsOneWidget);

      controller.nextStep();
      await tester.pump();
      controller.previousStep();
      await tester.pump();

      expect(
        container.read(onboardingControllerProvider).calculationMethod,
        CalculationMethods.isna,
      );
    });

    testWidgets('step 3 has madhab pre-selected', (tester) async {
      await pumpOnboarding(tester);
      setStep(tester, const OnboardingState(currentStep: 2));
      await tester.pump();

      expect(find.text(MadhabOptions.standard), findsOneWidget);
      expect(find.text(MadhabOptions.hanafi), findsOneWidget);
    });

    testWidgets('shows three progress indicators', (tester) async {
      await pumpOnboarding(tester);

      final activeBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == AppColors.primaryGreen,
      );
      expect(activeBars, findsNWidgets(1));

      setStep(tester, const OnboardingState(currentStep: 2));
      await tester.pump();
      expect(activeBars, findsNWidgets(3));
    });
  });
}
