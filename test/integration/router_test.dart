import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('GoRouter redirects', () {
    testWidgets('testUnauthenticatedRedirect sends user to login', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestRouterApp(overrides: authOverrides(user: null)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('testOnboardingRedirect sends incomplete user to onboarding',
        (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid', email: 'x@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await tester.pumpWidget(
        buildTestRouterApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => mockAuth.authStateChanges()),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(const UserSettings(onboardingComplete: false)),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('Enable Location'), findsOneWidget);
    });

    testWidgets('testFullySetupUserReachesHome', (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid-home', email: 'home@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await tester.pumpWidget(
        buildTestRouterApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => mockAuth.authStateChanges()),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings(onboardingComplete: true)),
            ),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: cairoPrayers(),
                isLoading: false,
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Prayer Times'), findsOneWidget);
    });

    testWidgets('testBottomNavTabSwitching shows placeholder tabs', (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid-nav', email: 'nav@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await tester.pumpWidget(
        buildTestRouterApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith(
              (ref) => mockAuth.authStateChanges(),
            ),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings(onboardingComplete: true)),
            ),
            prayerStateOverride(
              PrayerState(todaysPrayers: cairoPrayers(), isLoading: false),
            ),
            countdownOverride(const Duration(minutes: 30)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Prayer Times'), findsOneWidget);

      await tester.tap(find.text('Planner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Smart Day Planner'), findsOneWidget);

      await tester.tap(find.text('Commute'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Smart Commute Advisor'), findsOneWidget);

      final navBar = find.byType(NavigationBar);

      for (final label in ['Home', 'Places', 'Community', 'Analytics']) {
        await tester.tap(
          find.descendant(
            of: navBar,
            matching: find.text(label),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        if (label == 'Community') {
          expect(find.text('Accountability Circles'), findsOneWidget);
        }
        if (label == 'Analytics') {
          expect(find.textContaining('Private to you'), findsOneWidget);
        }
      }
    });
  });
}
