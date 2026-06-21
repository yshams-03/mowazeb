import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/services/analytics_engine.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/planner/models/routine_block.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

void main() {
  group('CorrelationEngine (AnalyticsEngine.buildScheduleInsights)', () {
    RoutineBlock lateNightStudy() => const RoutineBlock(
          id: 'study',
          title: 'Late Night Study',
          location: 'Home',
          startTime: TimeOfDay(hour: 21, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 30),
          daysOfWeek: [0, 1, 2, 3, 4],
          color: Colors.blue,
        );

    Map<String, Map<PrayerName, PrayerLogEntry>> logsWithMissedFajr(int days) {
      final logs = <String, Map<PrayerName, PrayerLogEntry>>{};
      for (var i = 0; i < days; i++) {
        final date = DateTime(2026, 6, 16 + i);
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        logs[key] = {
          PrayerName.fajr: const PrayerLogEntry(
            prayerName: PrayerName.fajr,
            status: PrayerLogStatus.missed,
          ),
          for (final p in PrayerName.values.where((p) => p != PrayerName.fajr))
            p: PrayerLogEntry.completed(p),
        };
      }
      return logs;
    }

    test('late-night study block correlates with missed Fajr', () {
      final insights = AnalyticsEngine.buildScheduleInsights(
        logsByDate: logsWithMissedFajr(5),
        blocks: [lateNightStudy()],
      );

      expect(
        insights.any((i) => i.message.contains('Late Night Study')),
        isTrue,
      );
    });

    test('empty logs returns placeholder insight', () {
      final insights = AnalyticsEngine.buildScheduleInsights(
        logsByDate: const {},
        blocks: [lateNightStudy()],
      );

      expect(insights, isEmpty);
    });

    test('all prayers completed yields no negative block insight', () {
      final logs = <String, Map<PrayerName, PrayerLogEntry>>{};
      for (var i = 0; i < 5; i++) {
        final date = DateTime(2026, 6, 16 + i);
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        logs[key] = {
          for (final p in PrayerName.values) p: PrayerLogEntry.completed(p),
        };
      }

      final insights = AnalyticsEngine.buildScheduleInsights(
        logsByDate: logs,
        blocks: [lateNightStudy()],
      );

      expect(
        insights.any((i) => i.message.contains('miss Fajr')),
        isFalse,
      );
    });

    test('high completion rate on weekday is reflected in daily completions', () {
      final logs = logsWithMissedFajr(1);
      logs['2026-06-20'] = {
        for (final p in PrayerName.values) p: PrayerLogEntry.completed(p),
      };

      final completions = AnalyticsEngine.buildDailyCompletions(
        dateKeys: ['2026-06-20', '2026-06-21'],
        logsByDate: logs,
      );

      expect(completions.first.completedCount, 5);
    });
  });
}
