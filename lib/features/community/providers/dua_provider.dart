import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dua_request.dart';

final duaRequestsProvider =
    StreamProvider.family<List<DuaRequest>, String>((ref, circleId) {
  return ref
      .watch(firestoreProvider)
      .collection(FirestorePaths.duaRequests(circleId))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => DuaRequest.fromFirestore(doc.id, doc.data()))
            .toList(),
      );
});

final duaActionsProvider = Provider<DuaActions>((ref) {
  return DuaActions(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class DuaActions {
  DuaActions(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> postRequest({
    required String circleId,
    required String message,
    required String authorName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    await _firestore.collection(FirestorePaths.duaRequests(circleId)).add({
      'authorUid': user.uid,
      'authorName': authorName,
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'duaSenders': <String>[],
    });
  }

  Future<void> sendDua({
    required String circleId,
    required String requestId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('sendDua');
    await callable.call<Map<String, dynamic>>({
      'circleId': circleId,
      'requestId': requestId,
    });
  }

  Future<void> sendDuaForMissedPrayer({
    required String circleId,
    required String targetUid,
    required String prayerName,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('sendDuaForMissedPrayer');
    await callable.call<Map<String, dynamic>>({
      'circleId': circleId,
      'targetUid': targetUid,
      'prayerName': prayerName,
    });
  }
}
