import '../models/prayer_context.dart';
import '../models/routine_block.dart';
import '../../prayer/models/prayer_time_model.dart';

/// Maps weekday [DateTime.weekday] (1=Mon … 7=Sun) to planner index 0=Mon … 6=Sun.
int weekdayIndex(DateTime date) => date.weekday - 1;

class PlannerEngine {
  PlannerEngine._();

  static const transitionWindowMinutes = 15;
  static const wuduLeadMinutes = 10;

  static List<PrayerContext> buildDailyContexts({
    required List<PrayerTimeModel> prayers,
    required List<RoutineBlock> blocks,
    required DateTime date,
  }) {
    return prayers
        .map((p) => classifyPrayer(
              prayerName: p.name.displayName,
              prayerTime: p.time,
              blocks: blocks,
              date: date,
            ))
        .toList();
  }

  static PrayerContext classifyPrayer({
    required String prayerName,
    required DateTime prayerTime,
    required List<RoutineBlock> blocks,
    required DateTime date,
  }) {
    final dayIndex = weekdayIndex(date);
    final prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;

    RoutineBlock? containingBlock;
    for (final block in blocks) {
      if (!block.appliesOnWeekday(dayIndex)) continue;
      if (_isInsideBlock(prayerMinutes, block)) {
        containingBlock = block;
        break;
      }
    }

    if (containingBlock != null) {
      return PrayerContext(
        prayerName: prayerName,
        prayerTime: prayerTime,
        tag: PrayerTag.atLocation,
        blockTitle: containingBlock.title,
        blockLocation: containingBlock.location,
      );
    }

    RoutineBlock? transitionBlock;
    for (final block in blocks) {
      if (!block.appliesOnWeekday(dayIndex)) continue;
      if (_isNearBlockEnd(prayerMinutes, block)) {
        transitionBlock = block;
        break;
      }
    }

    if (transitionBlock != null) {
      return PrayerContext(
        prayerName: prayerName,
        prayerTime: prayerTime,
        tag: PrayerTag.transition,
        blockTitle: transitionBlock.title,
        blockLocation: transitionBlock.location,
        wuduNudgeTime: prayerTime.subtract(
          const Duration(minutes: wuduLeadMinutes),
        ),
      );
    }

    return PrayerContext(
      prayerName: prayerName,
      prayerTime: prayerTime,
      tag: PrayerTag.atHome,
    );
  }

  static bool _isInsideBlock(int prayerMinutes, RoutineBlock block) {
    if (block.endMinutes <= block.startMinutes) return false;
    return prayerMinutes >= block.startMinutes &&
        prayerMinutes <= block.endMinutes;
  }

  static bool _isNearBlockEnd(int prayerMinutes, RoutineBlock block) {
    if (block.endMinutes <= block.startMinutes) return false;
    final windowStart = block.endMinutes - transitionWindowMinutes;
    final windowEnd = block.endMinutes + transitionWindowMinutes;
    return prayerMinutes >= windowStart &&
        prayerMinutes <= windowEnd &&
        !_isInsideBlock(prayerMinutes, block);
  }

  static List<RoutineBlock> blocksForDay(
    List<RoutineBlock> blocks,
    int dayIndex,
  ) {
    return blocks.where((b) => b.appliesOnWeekday(dayIndex)).toList();
  }
}
