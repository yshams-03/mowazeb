import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/auth/screens/register_screen.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Auth flow routing', () {
    testWidgets('testFullSignUpFlow navigates to onboarding after register',
        (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();

      await tester.pumpWidget(
        buildTestRouterApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => testAuthStateChanges(mockAuth)),
            immediateUserSettingsOverride(),
            authControllerProvider.overrideWith(
              (ref) => AuthController(mockAuth, GoogleSignIn(), firestore),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(
        find.ancestor(
          of: find.text('Register'),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Account'), findsWidgets);

      final email =
          'test_${DateTime.now().millisecondsSinceEpoch}@ummahpulse.test';
      final fields = find.descendant(
        of: find.byType(RegisterScreen),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), 'TestPass123!');
      await tester.enterText(fields.at(2), 'TestPass123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(mockAuth.currentUser, isNotNull,
          reason: 'Register should sign the user in');
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Find Your Location'), findsOneWidget);
    });

    testWidgets('testSignInWithExistingAccount routes to home', (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'test-uid',
        email: 'user@test.com',
        displayName: 'Test User',
      );
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
              PrayerState(todaysPrayers: cairoPrayers(), isLoading: false),
            ),
            countdownOverride(const Duration(minutes: 30)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Prayer Times'), findsOneWidget);
    });

    testWidgets('testSignInWithIncompleteOnboarding routes to onboarding',
        (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid-2', email: 'a@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await tester.pumpWidget(
        buildTestRouterApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) => mockAuth.authStateChanges()),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(
                const UserSettings(onboardingComplete: false),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Find Your Location'), findsOneWidget);
    });

    testWidgets('testAuthPersistence keeps authenticated user on home', (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid-3', email: 'b@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      final overrides = [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        authStateProvider.overrideWith((ref) => mockAuth.authStateChanges()),
        userSettingsProvider.overrideWith(
          (ref) => Stream.value(cairoSettings(onboardingComplete: true)),
        ),
        prayerStateOverride(
          PrayerState(todaysPrayers: cairoPrayers(), isLoading: false),
        ),
        countdownOverride(const Duration(minutes: 30)),
      ];

      await tester.pumpWidget(buildTestRouterApp(overrides: overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Prayer Times'), findsOneWidget);

      await tester.pumpWidget(buildTestRouterApp(overrides: overrides));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Prayer Times'), findsOneWidget);
    });

    testWidgets('testLogoutRedirectsToLogin', (tester) async {
      setLargeScreen(tester);
      final mockUser = MockUser(uid: 'uid-logout', email: 'logout@test.com');
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
              PrayerState(todaysPrayers: cairoPrayers(), isLoading: false),
            ),
            countdownOverride(const Duration(minutes: 30)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Prayer Times'), findsOneWidget);

      await mockAuth.signOut();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockAuth.currentUser, isNull);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
