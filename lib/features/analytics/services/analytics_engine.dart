import '../../community/models/prayer_log_entry.dart';
import '../../planner/models/routine_block.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/services/prayer_calculator.dart';
import '../models/analytics_models.dart';

/// Pure analytics calculations from prayer logs + routine blocks.
class AnalyticsEngine {
  AnalyticsEngine._();

  static String _dateKey(DateTime date) => PrayerCalculator.dateKeyFor(date);

  static List<String> lastNDaysKeys(int days, {DateTime? anchor}) {
    final end = anchor ?? DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(end.year, end.month, end.day - (days - 1 - i));
      return _dateKey(d);
    });
  }

  static int countCompleted(Map<PrayerName, PrayerLogEntry> entries) {
    return entries.values
        .where((e) => e.status == PrayerLogStatus.completed || e.checkedOff)
        .length;
  }

  static List<DailyCompletion> buildDailyCompletions({
    required List<String> dateKeys,
    required Map<String, Map<PrayerName, PrayerLogEntry>> logsByDate,
  }) {
    return dateKeys
        .map(
          (key) => DailyCompletion(
            dateKey: key,
            completedCount: countCompleted(
              logsByDate[key] ?? const {},
            ),
          ),
        )
        .toList();
  }

  static List<PrayerDelayStats> buildPrayerDelays({
    required Map<String, Map<PrayerName, PrayerLogEntry>> logsByDate,
    required Map<String, List<PrayerTimeModel>> prayerTimesByDate,
  }) {
    return PrayerName.values.map((prayer) {
      final delays = <double>[];
      for (final entry in logsByDate.entries) {
        final log = entry.value[prayer];
        if (log == null ||
            log.checkedAt == null ||
            log.status != PrayerLogStatus.completed) {
          continue;
        }
        final scheduled = prayerTimesByDate[entry.key]
            ?.where((p) => p.name == prayer)
            .firstOrNull;
        if (scheduled == null) continue;

        final delayMinutes =
            log.checkedAt!.difference(scheduled.time).inMinutes.toDouble();
        delays.add(delayMinutes);
      }

      final avg = delays.isEmpty
          ? 0.0
          : delays.reduce((a, b) => a + b) / delays.length;

      return PrayerDelayStats(
        prayer: prayer,
        averageDelayMinutes: avg,
        sampleCount: delays.length,
      );
    }).toList();
  }

  static List<HeatmapCellStats> buildHeatmap({
    required int weeks,
    required Map<String, Map<PrayerName, PrayerLogEntry>> logsByDate,
  }) {
    final now = DateTime.now();
    final cells = <HeatmapCellStats>[];

    for (var weekday = 0; weekday < 7; weekday++) {
      for (final prayer in PrayerName.values) {
        var completed = 0;
        var total = 0;

        for (var w = 0; w < weeks; w++) {
          final target = now.subtract(Duration(days: w * 7));
          final dayOffset = (target.weekday - 1 - weekday + 7) % 7;
          final date = DateTime(target.year, target.month, target.day - dayOffset);
          if (date.isAfter(now)) continue;

          total++;
          final key = _dateKey(date);
          final entry = logsByDate[key]?[prayer];
          if (entry != null &&
              (entry.checkedOff || entry.status == PrayerLogStatus.completed)) {
            completed++;
          }
        }

        cells.add(
          HeatmapCellStats(
            weekday: weekday,
            prayer: prayer,
            completedWeeks: completed,
            totalWeeks: total,
          ),
        );
      }
    }

    return cells;
  }

  static List<ScheduleInsight> buildScheduleInsights({
    required Map<String, Map<PrayerName, PrayerLogEntry>> logsByDate,
    required List<RoutineBlock> blocks,
  }) {
    final insights = <ScheduleInsight>[];

    for (final block in blocks) {
      var missedAfterBlock = 0;
      var totalDays = 0;

      for (final entry in logsByDate.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 3) continue;
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final weekday = date.weekday - 1;
        if (!block.appliesOnWeekday(weekday)) continue;

        totalDays++;
        final fajr = entry.value[PrayerName.fajr];
        final missed = fajr == null ||
            fajr.status == PrayerLogStatus.missed ||
            (!fajr.checkedOff && fajr.status != PrayerLogStatus.completed);

        final endsLate = block.endMinutes >= 22 * 60 || block.startMinutes >= 21 * 60;
        if (endsLate && missed) missedAfterBlock++;
      }

      if (totalDays >= 3 && missedAfterBlock >= 2) {
        insights.add(
          ScheduleInsight(
            message:
                "You miss Fajr most often the morning after a '${block.title}' block "
                '($missedAfterBlock of $totalDays days).',
          ),
        );
      }
    }

    if (insights.isEmpty && logsByDate.isNotEmpty) {
      insights.add(
        const ScheduleInsight(
          message:
              'Keep logging prayers — schedule correlations appear as more data builds up.',
        ),
      );
    }

    return insights;
  }
}

extension _FirstOrNullAnalytics<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
