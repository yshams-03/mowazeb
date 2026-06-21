import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_status.dart';

final userStatusProvider = StreamProvider.family<UserStatus, String>((ref, uid) {
  return ref.watch(firestoreProvider).doc(FirestorePaths.userStatus(uid)).snapshots().map((snapshot) {
    final status = UserStatus.fromFirestore(snapshot.data());
    if (status.isExpired && status.current != UserPresenceStatus.active) {
      return const UserStatus(current: UserPresenceStatus.active);
    }
    return status;
  });
});

final currentUserStatusProvider = StreamProvider<UserStatus>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return Stream.value(const UserStatus());
  }

  return ref.watch(firestoreProvider).doc(FirestorePaths.userStatus(uid)).snapshots().map((snapshot) {
    final status = UserStatus.fromFirestore(snapshot.data());
    if (status.isExpired && status.current != UserPresenceStatus.active) {
      return const UserStatus(current: UserPresenceStatus.active);
    }
    return status;
  });
});

final statusActionsProvider = Provider<StatusActions>((ref) {
  return StatusActions(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class StatusActions {
  StatusActions(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> setStatus({
    required UserPresenceStatus status,
    Duration? expiresAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final expiresAt = expiresAfter != null
        ? DateTime.now().add(expiresAfter)
        : null;

    final data = UserStatus(
      current: status,
      expiresAt: expiresAt,
    ).toFirestore();

    if (expiresAt == null) {
      data['expiresAt'] = FieldValue.delete();
    }

    await _firestore.doc(FirestorePaths.userStatus(user.uid)).set(
          data,
          SetOptions(merge: true),
        );
  }
}
