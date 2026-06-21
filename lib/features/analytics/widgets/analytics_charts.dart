import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../models/analytics_models.dart';

class CompletionChart extends StatelessWidget {
  const CompletionChart({super.key, required this.data});

  final List<DailyCompletion> data;

  Color _barColor(int count, BuildContext context) {
    if (count >= 5) return AppColors.primaryTeal;
    if (count >= 3) return AppColors.accentGold;
    return Theme.of(context).colorScheme.error.withValues(alpha: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    final axisColor = Theme.of(context).hintColor;
    if (data.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No completion data yet')),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: 5,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 24),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % 5 != 0 && index != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final parts = data[index].dateKey.split('-');
                  return Text(
                    '${parts[2]}/${parts[1]}',
                    style: TextStyle(fontSize: 9, color: axisColor),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].completedCount.toDouble(),
                    color: _barColor(data[i].completedCount, context),
                    width: 6,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class PrayerTimingChart extends StatelessWidget {
  const PrayerTimingChart({super.key, required this.stats});

  final List<PrayerDelayStats> stats;

  @override
  Widget build(BuildContext context) {
    final withData = stats.where((s) => s.sampleCount > 0).toList();
    if (withData.isEmpty) {
      return const Text('Check off prayers to see timing patterns.');
    }

    final maxDelay = withData
        .map((s) => s.averageDelayMinutes.abs())
        .fold<double>(0, (a, b) => a > b ? a : b)
        .clamp(15, 120);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: withData.map((stat) {
        final normalized = (stat.averageDelayMinutes.abs() / maxDelay).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.insightLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: normalized,
                  minHeight: 8,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: stat.averageDelayMinutes <= 5
                      ? AppColors.successGreen
                      : AppColors.accentGold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class WeeklyHeatmap extends StatefulWidget {
  const WeeklyHeatmap({super.key, required this.cells});

  final List<HeatmapCellStats> cells;

  @override
  State<WeeklyHeatmap> createState() => _WeeklyHeatmapState();
}

class _WeeklyHeatmapState extends State<WeeklyHeatmap> {
  String? _selectedLabel;

  Color _cellColor(double rate) {
    if (rate >= 0.8) return AppColors.primaryTeal;
    if (rate >= 0.5) return AppColors.accentGold;
    if (rate > 0) return AppColors.errorRed.withValues(alpha: 0.7);
    return Colors.grey.withValues(alpha: 0.25);
  }

  HeatmapCellStats? _cell(int weekday, PrayerName prayer) {
    for (final cell in widget.cells) {
      if (cell.weekday == weekday && cell.prayer == prayer) return cell;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 36),
            for (final label in dayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
          ],
        ),
        for (final prayer in PrayerName.values) ...[
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  prayer.displayName.substring(0, 1),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              for (var day = 0; day < 7; day++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final cell = _cell(day, prayer) ??
                          HeatmapCellStats(
                            weekday: day,
                            prayer: prayer,
                            completedWeeks: 0,
                            totalWeeks: 0,
                          );
                      setState(() => _selectedLabel = cell.tapLabel);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 22,
                      decoration: BoxDecoration(
                        color: _cellColor(_cell(day, prayer)?.rate ?? 0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (_selectedLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedLabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ],
    );
  }
}
