import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/models/prayer_log_entry.dart';
import '../../planner/providers/planner_provider.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/services/prayer_calculator.dart';
import '../models/analytics_models.dart';
import '../models/badge_model.dart';
import '../models/streak_model.dart';
import '../services/analytics_engine.dart';
import '../services/streak_cache_service.dart';

final personalStreakProvider = StreamProvider<StreakData>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(const StreakData());

  return ref.watch(firestoreProvider).doc(FirestorePaths.userStreak(uid)).snapshots().map((snap) {
    final streak = StreakData.fromFirestore(snap.data());
    ref.read(streakCacheServiceProvider.future).then(
          (cache) => cache.cache(
            current: streak.currentStreak,
            longest: streak.longestStreak,
          ),
        );
    return streak;
  });
});

final userBadgesProvider = StreamProvider<List<UserBadge>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(const []);

  return ref.watch(firestoreProvider).collection(FirestorePaths.userBadges(uid)).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => UserBadge.fromFirestore(doc.id, doc.data()))
            .toList(),
      );
});

final analyticsSnapshotProvider = FutureProvider<AnalyticsSnapshot>((ref) async {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const AnalyticsSnapshot(isLoading: false);

  final firestore = ref.watch(firestoreProvider);
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  final blocks = ref.watch(plannerProvider).blocks;

  if (settings == null || !settings.isComplete) {
    return const AnalyticsSnapshot(isLoading: false);
  }

  final dateKeys = AnalyticsEngine.lastNDaysKeys(30);
  final logsByDate = <String, Map<PrayerName, PrayerLogEntry>>{};
  final prayerTimesByDate = <String, List<PrayerTimeModel>>{};

  for (final key in dateKeys) {
    final parts = key.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    prayerTimesByDate[key] = PrayerCalculator.calculateFromSettings(
      settings,
      date: date,
    );

    final snap = await firestore
        .collection(FirestorePaths.prayerLogEntries(uid, key))
        .get();

    final entries = <PrayerName, PrayerLogEntry>{};
    for (final prayer in PrayerName.values) {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      for (final d in snap.docs) {
        if (d.id == prayer.name) {
          doc = d;
          break;
        }
      }
      entries[prayer] = PrayerLogEntry.fromFirestore(prayer, doc?.data());
    }
    logsByDate[key] = entries;
  }

  return AnalyticsSnapshot(
    dailyCompletions: AnalyticsEngine.buildDailyCompletions(
      dateKeys: dateKeys,
      logsByDate: logsByDate,
    ),
    prayerDelays: AnalyticsEngine.buildPrayerDelays(
      logsByDate: logsByDate,
      prayerTimesByDate: prayerTimesByDate,
    ),
    insights: AnalyticsEngine.buildScheduleInsights(
      logsByDate: logsByDate,
      blocks: blocks,
    ),
    heatmap: AnalyticsEngine.buildHeatmap(
      weeks: 8,
      logsByDate: logsByDate,
    ),
    isLoading: false,
  );
});

final correlationInsightsProvider = Provider<AsyncValue<List<ScheduleInsight>>>((ref) {
  return ref.watch(analyticsSnapshotProvider).whenData((s) => s.insights);
});

final unlockedBadgeIdsProvider = Provider<Set<BadgeId>>((ref) {
  final badges = ref.watch(userBadgesProvider).valueOrNull ?? const [];
  return badges.map((b) => b.badgeId).toSet();
});
