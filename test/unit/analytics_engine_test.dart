import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/services/analytics_engine.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/planner/models/routine_block.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:flutter/material.dart';

void main() {
  group('AnalyticsEngine', () {
    test('countCompleted counts completed prayers', () {
      final entries = {
        PrayerName.fajr: PrayerLogEntry.completed(PrayerName.fajr),
        PrayerName.dhuhr: const PrayerLogEntry(prayerName: PrayerName.dhuhr),
      };
      expect(AnalyticsEngine.countCompleted(entries), 1);
    });

    test('buildDailyCompletions maps date keys', () {
      final result = AnalyticsEngine.buildDailyCompletions(
        dateKeys: ['2026-06-20', '2026-06-21'],
        logsByDate: {
          '2026-06-20': {
            for (final p in PrayerName.values) p: PrayerLogEntry.completed(p),
          },
          '2026-06-21': {
            PrayerName.fajr: PrayerLogEntry.completed(PrayerName.fajr),
          },
        },
      );

      expect(result[0].completedCount, 5);
      expect(result[1].completedCount, 1);
    });

    test('buildScheduleInsights detects late block pattern', () {
      final logs = <String, Map<PrayerName, PrayerLogEntry>>{};
      for (var i = 0; i < 5; i++) {
        final date = DateTime(2026, 6, 16 + i);
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        logs[key] = {
          PrayerName.fajr: const PrayerLogEntry(
            prayerName: PrayerName.fajr,
            status: PrayerLogStatus.missed,
          ),
        };
      }

      const block = RoutineBlock(
        id: 'b1',
        title: 'Late Night Study',
        location: 'Home',
        startTime: TimeOfDay(hour: 21, minute: 0),
        endTime: TimeOfDay(hour: 23, minute: 30),
        daysOfWeek: [0, 1, 2, 3, 4],
        color: Colors.blue,
      );

      final insights = AnalyticsEngine.buildScheduleInsights(
        logsByDate: logs,
        blocks: [block],
      );

      expect(insights.any((i) => i.message.contains('Late Night Study')), isTrue);
    });
  });
}
