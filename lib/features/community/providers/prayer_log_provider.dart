import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/services/prayer_calculator.dart';
import '../models/prayer_log_entry.dart';

typedef TodayPrayerLogs = Map<PrayerName, PrayerLogEntry>;

final todayPrayerLogsProvider = StreamProvider<TodayPrayerLogs>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) {
    return Stream.value(const {});
  }

  final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
  return ref.watch(firestoreProvider).collection(FirestorePaths.prayerLogEntries(uid, dateKey)).snapshots().map((snapshot) {
    final entries = <PrayerName, PrayerLogEntry>{};
    for (final prayer in PrayerName.values) {
      final doc = snapshot.docs.where((d) => d.id == prayer.name).firstOrNull;
      entries[prayer] = PrayerLogEntry.fromFirestore(
        prayer,
        doc?.data(),
      );
    }
    return entries;
  });
});

final prayerLogActionsProvider = Provider<PrayerLogActions>((ref) {
  return PrayerLogActions(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class PrayerLogActions {
  PrayerLogActions(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> checkOff(PrayerName prayer) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
    final entry = PrayerLogEntry.completed(prayer);

    await _firestore.doc(FirestorePaths.prayerLogEntry(user.uid, dateKey, prayer.name)).set(
          entry.toFirestore(),
          SetOptions(merge: true),
        );
  }
}

class PrayerLogNotifier extends StateNotifier<TodayPrayerLogs> {
  PrayerLogNotifier(this._actions, this._ref) : super(const {}) {
    _ref.listen<AsyncValue<TodayPrayerLogs>>(todayPrayerLogsProvider, (_, next) {
      next.whenData((logs) {
        if (!_hasPendingOptimistic) {
          if (_logsEqual(state, logs)) return;
          state = logs;
        } else {
          final merged = _mergeWithOptimistic(logs);
          if (_logsEqual(state, merged)) return;
          state = merged;
        }
      });
    });
  }

  static bool _logsEqual(TodayPrayerLogs a, TodayPrayerLogs b) {
    if (a.length != b.length) return false;
    for (final prayer in PrayerName.values) {
      final left = a[prayer];
      final right = b[prayer];
      if (left == null && right == null) continue;
      if (left == null || right == null) return false;
      if (left.checkedOff != right.checkedOff ||
          left.status != right.status ||
          left.checkedAt != right.checkedAt) {
        return false;
      }
    }
    return true;
  }

  final PrayerLogActions _actions;
  final Ref _ref;
  final Set<PrayerName> _optimisticPending = {};

  bool get _hasPendingOptimistic => _optimisticPending.isNotEmpty;

  TodayPrayerLogs _mergeWithOptimistic(TodayPrayerLogs remote) {
    final merged = Map<PrayerName, PrayerLogEntry>.from(remote);
    for (final prayer in _optimisticPending) {
      merged[prayer] = state[prayer] ?? PrayerLogEntry.completed(prayer);
    }
    return merged;
  }

  Future<void> checkOff(PrayerName prayer) async {
    final previous = state;
    _optimisticPending.add(prayer);
    state = {
      ...state,
      prayer: PrayerLogEntry.completed(prayer),
    };

    try {
      await _actions.checkOff(prayer);
    } catch (_) {
      state = previous;
    } finally {
      _optimisticPending.remove(prayer);
      final remote = _ref.read(todayPrayerLogsProvider).valueOrNull;
      if (remote != null) {
        state = remote;
      }
    }
  }
}

final prayerLogNotifierProvider =
    StateNotifierProvider<PrayerLogNotifier, TodayPrayerLogs>((ref) {
  return PrayerLogNotifier(
    ref.watch(prayerLogActionsProvider),
    ref,
  );
});

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
