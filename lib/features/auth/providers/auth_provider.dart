import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_settings.dart';
import '../../../firebase_options.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    serverClientId: DefaultFirebaseOptions.googleWebClientId,
  );
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userSettingsProvider = StreamProvider<UserSettings>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return Stream.value(const UserSettings());
  }

  return ref.watch(firestoreProvider).doc(FirestorePaths.userSettings(user.uid)).snapshots().map(
        (snapshot) => UserSettings.fromFirestore(snapshot.data()),
      );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._googleSignIn, this._firestore)
      : super(const AsyncData(null));

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _createUserDocument(credential.user!);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception(
          'Google sign-in did not return an ID token. Check Firebase Google Auth setup.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _createUserDocument(user);
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    });
  }

  Future<void> _createUserDocument(User user) async {
    final docRef = _firestore.doc(FirestorePaths.userDoc(user.uid));
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .doc(FirestorePaths.userSettings(user.uid))
          .set(const UserSettings().toFirestore());
    }
  }

  void resetError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(firestoreProvider),
  );
});
