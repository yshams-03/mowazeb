import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/models/streak_model.dart';

void main() {
  group('StreakData', () {
    test('fromFirestore parses streak fields', () {
      final streak = StreakData.fromFirestore({
        'currentStreak': 5,
        'longestStreak': 12,
        'lastCompletedDate': '2026-06-20',
      });

      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 12);
      expect(streak.lastCompletedDate, '2026-06-20');
    });
  });
}
