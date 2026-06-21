import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../models/prayer_context.dart';
import '../models/routine_block.dart';
import '../services/planner_engine.dart';

class PlannerState {
  const PlannerState({
    this.blocks = const [],
    this.todayContexts = const [],
    this.isLoading = true,
    this.error,
  });

  final List<RoutineBlock> blocks;
  final List<PrayerContext> todayContexts;
  final bool isLoading;
  final String? error;

  PlannerState copyWith({
    List<RoutineBlock>? blocks,
    List<PrayerContext>? todayContexts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PlannerState(
      blocks: blocks ?? this.blocks,
      todayContexts: todayContexts ?? this.todayContexts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref,
  );
});

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(
    this._firestore,
    this._auth,
    this._ref, {
    PlannerState? initialState,
    bool autoInit = true,
  }) : super(initialState ?? const PlannerState()) {
    if (autoInit && initialState == null) {
      _init();
    }
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _blocksSub;

  String? _lastPrayerScheduleKey;

  void _init() {
    _ref.listen<PrayerState>(prayerProvider, (previous, next) {
      if (next.isLoading || next.error != null || next.todaysPrayers.isEmpty) {
        return;
      }
      final key = next.todaysPrayers
          .map((p) => '${p.name.name}:${p.time.toIso8601String()}')
          .join('|');
      if (key == _lastPrayerScheduleKey) return;
      _lastPrayerScheduleKey = key;
      _recomputeContexts();
    });

    final user = _auth.currentUser;
    if (user != null) {
      _watchBlocks(user.uid);
    }

    _ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          _watchBlocks(user.uid);
        } else {
          _blocksSub?.cancel();
          state = const PlannerState(blocks: [], todayContexts: []);
        }
      });
    });
  }

  @override
  void dispose() {
    _blocksSub?.cancel();
    super.dispose();
  }

  void _watchBlocks(String uid) {
    _blocksSub?.cancel();
    _blocksSub = _firestore
        .collection(FirestorePaths.routineBlocks(uid))
        .snapshots()
        .listen(
      (snapshot) {
        final blocks = snapshot.docs
            .map((doc) => RoutineBlock.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

        state = state.copyWith(
          blocks: blocks,
          isLoading: false,
          clearError: true,
        );
        _recomputeContexts();
      },
      onError: (_) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load routine blocks.',
        );
      },
    );
  }

  void _recomputeContexts() {
    final prayerModels = _ref.read(prayerProvider).todaysPrayers;
    if (prayerModels.isEmpty) return;

    final contexts = PlannerEngine.buildDailyContexts(
      prayers: prayerModels,
      blocks: state.blocks,
      date: DateTime.now(),
    );

    state = state.copyWith(todayContexts: contexts);
    NotificationService.scheduleWuduNudges(contexts);
  }

  Future<void> addBlock(RoutineBlock block) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collection = _firestore.collection(FirestorePaths.routineBlocks(user.uid));
    final docRef =
        block.id.isEmpty ? collection.doc() : collection.doc(block.id);

    await docRef.set(block.copyWith(id: docRef.id).toFirestore());
  }

  Future<void> deleteBlock(String blockId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .doc(FirestorePaths.routineBlock(user.uid, blockId))
        .delete();
  }
}
