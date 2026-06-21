import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';

class _FakeGoogleSignIn implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignInMissingIdToken implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => _FakeGoogleAccount();

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAccount implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleAuthMissingIdToken();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAuthMissingIdToken implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'access-token';

  @override
  String? get idToken => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthController google sign-in', () {
    test('sets error when Google returns no id token', () async {
      final controller = AuthController(
        MockFirebaseAuth(),
        _FakeGoogleSignInMissingIdToken(),
        FakeFirebaseFirestore(),
      );

      await controller.signInWithGoogle();

      expect(controller.state.hasError, isTrue);
      expect(
        controller.state.error.toString(),
        contains('did not return an ID token'),
      );
    });
  });

  group('authControllerProvider', () {
    test('exposes AuthController via provider container', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
          googleSignInProvider.overrideWithValue(_FakeGoogleSignIn()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.registerWithEmail('provider@test.com', 'Pass123!');

      expect(auth.currentUser?.email, 'provider@test.com');
      expect(container.read(authControllerProvider).hasError, isFalse);
    });

    test('registerWithEmail trims whitespace from email', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
          googleSignInProvider.overrideWithValue(_FakeGoogleSignIn()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).registerWithEmail(
            '  spaced@test.com  ',
            'Pass123!',
          );

      expect(auth.currentUser?.email, 'spaced@test.com');
    });
  });
}
