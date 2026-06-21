import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_context.dart';
import '../models/routine_block.dart';
import '../services/planner_engine.dart';
import 'planner_calendar_constants.dart';

class WeeklyCalendarView extends StatelessWidget {
  const WeeklyCalendarView({
    super.key,
    required this.blocks,
    required this.todayContexts,
    this.onBlockTap,
  });

  final List<RoutineBlock> blocks;
  final List<PrayerContext> todayContexts;
  final ValueChanged<RoutineBlock>? onBlockTap;

  @override
  Widget build(BuildContext context) {
    final todayIndex = weekdayIndex(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HourLabels(isDark: isDark),
          for (var day = 0; day < 7; day++)
            _DayColumn(
              dayIndex: day,
              isToday: day == todayIndex,
              blocks: PlannerEngine.blocksForDay(blocks, day),
              prayerContexts: day == todayIndex ? todayContexts : const [],
              isDark: isDark,
              onBlockTap: onBlockTap,
            ),
        ],
      ),
    );
  }
}

class _HourLabels extends StatelessWidget {
  const _HourLabels({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: PlannerCalendarConstants.dayHeight + 28,
      child: Column(
        children: [
          const SizedBox(height: 28),
          for (var h = PlannerCalendarConstants.startHour;
              h < PlannerCalendarConstants.endHour;
              h++)
            SizedBox(
              height: PlannerCalendarConstants.hourHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, top: 2),
                  child: Text(
                    formatHourLabel(h),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.dayIndex,
    required this.isToday,
    required this.blocks,
    required this.prayerContexts,
    required this.isDark,
    this.onBlockTap,
  });

  final int dayIndex;
  final bool isToday;
  final List<RoutineBlock> blocks;
  final List<PrayerContext> prayerContexts;
  final bool isDark;
  final ValueChanged<RoutineBlock>? onBlockTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PlannerCalendarConstants.dayColumnWidth,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              PlannerCalendarConstants.dayLabels[dayIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: PlannerCalendarConstants.dayHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50,
            ),
            child: Stack(
              children: [
                for (var h = PlannerCalendarConstants.startHour;
                    h < PlannerCalendarConstants.endHour;
                    h++)
                  Positioned(
                    top: (h - PlannerCalendarConstants.startHour) *
                        PlannerCalendarConstants.hourHeight,
                    left: 0,
                    right: 0,
                    child: Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                for (final block in blocks)
                  Positioned(
                    top: minutesToTopOffset(block.startMinutes),
                    left: 4,
                    right: 4,
                    height: blockHeight(block).clamp(24, double.infinity),
                    child: _BlockChip(
                      block: block,
                      onTap: onBlockTap != null ? () => onBlockTap!(block) : null,
                    ),
                  ),
                for (final prayerCtx in prayerContexts)
                  Positioned(
                    top: minutesToTopOffset(
                      prayerCtx.prayerTime.hour * 60 + prayerCtx.prayerTime.minute,
                    ),
                    left: 0,
                    right: 0,
                    child: _PrayerMarker(prayerContext: prayerCtx),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockChip extends StatelessWidget {
  const _BlockChip({required this.block, this.onTap});

  final RoutineBlock block;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: block.color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (blockHeight(block) > 36)
                Text(
                  block.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerMarker extends StatelessWidget {
  const _PrayerMarker({required this.prayerContext});

  final PrayerContext prayerContext;

  @override
  Widget build(BuildContext context) {
    final ctx = prayerContext;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ctx.tag.summaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            ctx.prayerName,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: ctx.tag.summaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String formatPrayerTime(DateTime time) => DateFormat('h:mm a').format(time);
