import '../../prayer/models/prayer_time_model.dart';

class DailyCompletion {
  const DailyCompletion({
    required this.dateKey,
    required this.completedCount,
  });

  final String dateKey;
  final int completedCount;
}

class PrayerDelayStats {
  const PrayerDelayStats({
    required this.prayer,
    required this.averageDelayMinutes,
    required this.sampleCount,
  });

  final PrayerName prayer;
  final double averageDelayMinutes;
  final int sampleCount;

  String get insightLabel {
    if (sampleCount == 0) return 'No data yet';
    final minutes = averageDelayMinutes.round().abs();
    if (averageDelayMinutes <= 5) {
      return 'You usually pray ${prayer.displayName} on time';
    }
    if (averageDelayMinutes > 0) {
      return 'You usually pray ${prayer.displayName} $minutes minutes late';
    }
    return 'You usually pray ${prayer.displayName} ${minutes}m early';
  }
}

class ScheduleInsight {
  const ScheduleInsight({
    required this.message,
  });

  final String message;
}

class HeatmapCellStats {
  const HeatmapCellStats({
    required this.weekday,
    required this.prayer,
    required this.completedWeeks,
    required this.totalWeeks,
  });

  final int weekday;
  final PrayerName prayer;
  final int completedWeeks;
  final int totalWeeks;

  double get rate =>
      totalWeeks == 0 ? 0 : completedWeeks / totalWeeks;

  String get tapLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[weekday.clamp(0, 6)];
    return 'You completed ${prayer.displayName} on $day $completedWeeks/$totalWeeks weeks';
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    this.dailyCompletions = const [],
    this.prayerDelays = const [],
    this.insights = const [],
    this.heatmap = const [],
    this.isLoading = true,
  });

  final List<DailyCompletion> dailyCompletions;
  final List<PrayerDelayStats> prayerDelays;
  final List<ScheduleInsight> insights;
  final List<HeatmapCellStats> heatmap;
  final bool isLoading;

  AnalyticsSnapshot copyWith({
    List<DailyCompletion>? dailyCompletions,
    List<PrayerDelayStats>? prayerDelays,
    List<ScheduleInsight>? insights,
    List<HeatmapCellStats>? heatmap,
    bool? isLoading,
  }) {
    return AnalyticsSnapshot(
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
      prayerDelays: prayerDelays ?? this.prayerDelays,
      insights: insights ?? this.insights,
      heatmap: heatmap ?? this.heatmap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
