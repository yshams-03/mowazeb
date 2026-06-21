import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';

class _FakeGoogleSignIn implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthController', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late AuthController controller;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth();
      controller = AuthController(auth, _FakeGoogleSignIn(), firestore);
    });

    test('registerWithEmail creates user and Firestore document', () async {
      await controller.registerWithEmail('new@test.com', 'Pass123!');

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'new@test.com');

      final uid = auth.currentUser!.uid;
      final userDoc = await firestore.doc(FirestorePaths.userDoc(uid)).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['email'], 'new@test.com');

      final settings =
          await firestore.doc(FirestorePaths.userSettings(uid)).get();
      expect(settings.exists, isTrue);
    });

    test('signInWithEmail signs in existing user', () async {
      await controller.registerWithEmail('user@test.com', 'Pass123!');
      await controller.signOut();
      expect(auth.currentUser, isNull);

      await controller.signInWithEmail('user@test.com', 'Pass123!');

      expect(auth.currentUser, isNotNull);
      expect(controller.state.hasError, isFalse);
    });

    test('registerWithEmail reports loading then success', () async {
      final future = controller.registerWithEmail('new@test.com', 'Pass123!');
      expect(controller.state.isLoading, isTrue);

      await future;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.hasError, isFalse);
    });

    test('signOut clears current user', () async {
      await controller.registerWithEmail('user@test.com', 'Pass123!');
      expect(auth.currentUser, isNotNull);

      await controller.signOut();

      expect(auth.currentUser, isNull);
      expect(controller.state.hasError, isFalse);
    });

    test('signInWithGoogle sets error when cancelled', () async {
      await controller.signInWithGoogle();

      expect(controller.state.hasError, isTrue);
      expect(
        controller.state.error.toString(),
        contains('Google sign-in was cancelled'),
      );
    });

    test('resetError clears error state', () async {
      await controller.signInWithGoogle();
      expect(controller.state.hasError, isTrue);

      controller.resetError();

      expect(controller.state.hasError, isFalse);
    });

    test('second sign in does not duplicate Firestore user document', () async {
      await controller.registerWithEmail('user@test.com', 'Pass123!');
      final uid = auth.currentUser!.uid;

      await controller.signOut();
      await controller.signInWithEmail('user@test.com', 'Pass123!');

      final userDoc = await firestore.doc(FirestorePaths.userDoc(uid)).get();
      expect(userDoc.exists, isTrue);
    });
  });

  group('authStateProvider', () {
    test('emits user after registration', () async {
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          authStateProvider.overrideWith((ref) => auth.authStateChanges()),
        ],
      );
      addTearDown(container.dispose);

      final controller = AuthController(
        auth,
        _FakeGoogleSignIn(),
        FakeFirebaseFirestore(),
      );
      await controller.registerWithEmail('stream@test.com', 'Pass123!');

      expect(auth.currentUser?.email, 'stream@test.com');
    });
  });
}
