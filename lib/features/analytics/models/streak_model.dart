import 'package:cloud_firestore/cloud_firestore.dart';

class StreakData {
  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedDate;

  factory StreakData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const StreakData();
    return StreakData(
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastCompletedDate: data['lastCompletedDate'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastCompletedDate != null) 'lastCompletedDate': lastCompletedDate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class CircleStreakData {
  const CircleStreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastFullyCompletedDate,
  });

  final int currentStreak;
  final int longestStreak;
  final String? lastFullyCompletedDate;

  factory CircleStreakData.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const CircleStreakData();
    return CircleStreakData(
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastFullyCompletedDate: data['lastFullyCompletedDate'] as String?,
    );
  }
}
