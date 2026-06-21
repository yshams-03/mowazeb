import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/accountability_circle.dart';
import '../models/prayer_log_entry.dart';
import '../models/user_status.dart';
import '../services/invite_code_generator.dart';
import '../services/circle_invite_lookup.dart';
import '../services/stream_utils.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/services/prayer_calculator.dart';

final userCirclesProvider = StreamProvider<List<AccountabilityCircle>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return Stream.value(const []);
  }

  return ref
      .watch(firestoreProvider)
      .collection(FirestorePaths.circles())
      .where('members', arrayContains: uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => AccountabilityCircle.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

final circleProvider =
    StreamProvider.family<AccountabilityCircle?, String>((ref, circleId) {
  return ref.watch(firestoreProvider).doc(FirestorePaths.circle(circleId)).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AccountabilityCircle.fromFirestore(snapshot.id, snapshot.data()!);
  });
});

final circleFeedProvider =
    StreamProvider.family<List<MemberPrayerFeed>, String>((ref, circleId) {
  final circleAsync = ref.watch(circleProvider(circleId));
  final currentUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  final circle = circleAsync.valueOrNull;
  final firestore = ref.watch(firestoreProvider);

  if (circle == null || currentUid == null || circle.members.isEmpty) {
    return Stream.value(const []);
  }

  final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
  final memberStreams = circle.members.map((memberUid) {
    return _memberFeedStream(
      firestore: firestore,
      memberUid: memberUid,
      dateKey: dateKey,
      isCurrentUser: memberUid == currentUid,
    );
  }).toList();

  return combineLatestList(memberStreams).map((feeds) {
    return feeds.toList()
      ..sort((a, b) {
        if (a.isCurrentUser) return -1;
        if (b.isCurrentUser) return 1;
        return a.displayName.compareTo(b.displayName);
      });
  });
});

Stream<MemberPrayerFeed> _memberFeedStream({
  required FirebaseFirestore firestore,
  required String memberUid,
  required String dateKey,
  required bool isCurrentUser,
}) {
  final logsStream = firestore
      .collection(FirestorePaths.prayerLogEntries(memberUid, dateKey))
      .snapshots();

  final profileStream = firestore.doc(FirestorePaths.userDoc(memberUid)).snapshots();

  return logsStream.asyncMap((logsSnap) async {
    final profile = await profileStream.first;
    final data = profile.data();
    final displayName = data?['displayName'] as String? ??
        data?['email'] as String? ??
        'Member';

    final statusSnap =
        await firestore.doc(FirestorePaths.userStatus(memberUid)).get();
    final userStatus = UserStatus.fromFirestore(statusSnap.data());
    final presenceStatus = userStatus.effectiveStatus;

    final entries = <PrayerName, PrayerLogEntry>{};
    for (final prayer in PrayerName.values) {
      final doc = logsSnap.docs.where((d) => d.id == prayer.name).firstOrNull;
      entries[prayer] = PrayerLogEntry.fromFirestore(prayer, doc?.data());
    }

    return MemberPrayerFeed(
      uid: memberUid,
      displayName: displayName,
      entries: entries,
      isCurrentUser: isCurrentUser,
      presenceStatus: presenceStatus,
    );
  });
}

final circleActionsProvider = Provider<CircleActions>((ref) {
  return CircleActions(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class CreateCircleResult {
  const CreateCircleResult({this.circleId, this.inviteCode, this.error});

  final String? circleId;
  final String? inviteCode;
  final String? error;

  bool get isSuccess => circleId != null && inviteCode != null;
}

class CircleActions {
  CircleActions(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<CreateCircleResult> createCircle(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const CreateCircleResult(error: 'Sign in to create a circle.');
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const CreateCircleResult(error: 'Enter a circle name.');
    }

    try {
      var inviteCode = InviteCodeGenerator.generate();
      for (var attempt = 0; attempt < 5; attempt++) {
        final lookup = await _firestore
            .doc(CircleInviteLookup.docPath(inviteCode))
            .get();
        if (!lookup.exists) break;
        inviteCode = InviteCodeGenerator.generate();
      }

      final docRef = _firestore.collection(FirestorePaths.circles()).doc();
      final circle = AccountabilityCircle(
        id: docRef.id,
        name: trimmed,
        createdBy: user.uid,
        members: [user.uid],
        inviteCode: inviteCode,
      );

      final batch = _firestore.batch();
      batch.set(docRef, {
        ...circle.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        _firestore.doc(CircleInviteLookup.docPath(inviteCode)),
        CircleInviteLookup.toFirestore(
          circleId: docRef.id,
          createdBy: user.uid,
        ),
      );
      await batch.commit();
      await _addCircleIdToUser(user.uid, docRef.id);

      return CreateCircleResult(circleId: docRef.id, inviteCode: inviteCode);
    } on FirebaseException catch (e) {
      return CreateCircleResult(error: e.message ?? 'Could not create circle.');
    } catch (_) {
      return const CreateCircleResult(error: 'Could not create circle. Try again.');
    }
  }

  Future<String?> joinCircle(String inviteCode) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final normalized = inviteCode.trim().toUpperCase();
    if (normalized.length != 6) return null;

    final lookupSnap =
        await _firestore.doc(CircleInviteLookup.docPath(normalized)).get();
    if (!lookupSnap.exists) return null;

    final circleId = CircleInviteLookup.circleIdFrom(lookupSnap.data());
    if (circleId == null) return null;

    final doc = await _firestore.doc(FirestorePaths.circle(circleId)).get();
    if (!doc.exists || doc.data() == null) return null;
    final circle = AccountabilityCircle.fromFirestore(doc.id, doc.data()!);
    if (circle.members.contains(user.uid)) {
      return doc.id;
    }

    await doc.reference.update({
      'members': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addCircleIdToUser(user.uid, doc.id);

    return doc.id;
  }

  Future<void> _addCircleIdToUser(String uid, String circleId) async {
    await _firestore.doc(FirestorePaths.userSettings(uid)).set(
      {
        'circleIds': FieldValue.arrayUnion([circleId]),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}

extension _FirstOrNullCircle<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
