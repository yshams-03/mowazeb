import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/auth/screens/login_screen.dart';
import 'package:ummah_pulse/features/auth/screens/register_screen.dart';

import '../helpers/test_helpers.dart';

Override mockAuthControllerOverride({FakeFirebaseFirestore? firestore}) {
  final db = firestore ?? FakeFirebaseFirestore();
  return authControllerProvider.overrideWith(
    (ref) => AuthController(MockFirebaseAuth(), GoogleSignIn(), db),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('testLoginEmailValidation', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestGoRouterApp(
          router: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('testLoginInvalidEmailFormat', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(child: const LoginScreen()),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'notanemail');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('testNavigateToRegister', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestGoRouterApp(
          router: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
              GoRoute(
                path: RoutePaths.register,
                builder: (_, __) => const RegisterScreen(),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.ancestor(
          of: find.text('Register'),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Account'), findsWidgets);
    });
  });

  group('RegisterScreen', () {
    testWidgets('testRegisterPasswordMismatch', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [mockAuthControllerOverride()],
          child: const RegisterScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Pass123!');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'Different1!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('testRegisterAllFieldsValid', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [mockAuthControllerOverride()],
          child: const RegisterScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Pass123!');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'Pass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('testRegisterPasswordTooShort', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [mockAuthControllerOverride()],
          child: const RegisterScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'abc');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'abc',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });
}
