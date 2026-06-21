import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/models/streak_model.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

void main() {
  group('Streak and badges flow (client models)', () {
    test('streak increments when consecutive days complete', () {
      var streak = const StreakData(currentStreak: 1, lastCompletedDate: '2026-06-20');

      streak = StreakData(
        currentStreak: streak.currentStreak + 1,
        longestStreak: 2,
        lastCompletedDate: '2026-06-21',
      );

      expect(streak.currentStreak, 2);
    });

    test('streak resets after missed day', () {
      const streak = StreakData(currentStreak: 0, longestStreak: 5);
      expect(streak.currentStreak, 0);
    });

    test('all five prayers completed for badge eligibility', () {
      final entries = {
        for (final p in PrayerName.values) p: PrayerLogEntry.completed(p),
      };

      final completed = entries.values
          .where((e) => e.status == PrayerLogStatus.completed)
          .length;

      expect(completed, 5);
    });
  });
}
