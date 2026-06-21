import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';
import 'package:ummah_pulse/features/planner/models/routine_block.dart';
import 'package:ummah_pulse/features/planner/services/planner_engine.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

void main() {
  final wednesday = DateTime(2026, 6, 24);

  RoutineBlock blockA() => const RoutineBlock(
        id: 'a',
        title: 'University',
        location: 'University',
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 14, minute: 0),
        daysOfWeek: [0, 1, 2, 3, 4],
        color: Color(0xFF2196F3),
      );

  RoutineBlock blockB() => const RoutineBlock(
        id: 'b',
        title: 'Gym',
        location: 'Gym',
        startTime: TimeOfDay(hour: 16, minute: 0),
        endTime: TimeOfDay(hour: 17, minute: 30),
        daysOfWeek: [0, 2, 4],
        color: Color(0xFF4CAF50),
      );

  DateTime prayerTime(int hour, int minute) =>
      DateTime(wednesday.year, wednesday.month, wednesday.day, hour, minute);

  group('PlannerEngine', () {
    test('testPrayerInsideBlock', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: prayerTime(12, 30),
        blocks: [blockA()],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.atLocation);
      expect(context.displayTag, contains('University'));
    });

    test('testPrayerOutsideAllBlocks', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Fajr',
        prayerTime: prayerTime(5, 10),
        blocks: [blockA(), blockB()],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.atHome);
    });

    test('testTransitionWindow outside gap is atHome', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Asr',
        prayerTime: prayerTime(15, 45),
        blocks: [blockA()],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.atHome);
    });

    test('testTransitionWindow near block end', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: prayerTime(14, 5),
        blocks: [blockA()],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.transition);
    });

    test('testWuduNudgeScheduledForTransition', () {
      final prayer = prayerTime(14, 5);
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: prayer,
        blocks: [blockA()],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.transition);
      expect(context.wuduNudgeTime, prayer.subtract(const Duration(minutes: 10)));
    });

    test('testNoBlocksToday', () {
      final prayers = [
        PrayerTimeModel(name: PrayerName.fajr, time: prayerTime(5, 10)),
        PrayerTimeModel(name: PrayerName.dhuhr, time: prayerTime(12, 30)),
        PrayerTimeModel(name: PrayerName.asr, time: prayerTime(15, 45)),
        PrayerTimeModel(name: PrayerName.maghrib, time: prayerTime(18, 20)),
        PrayerTimeModel(name: PrayerName.isha, time: prayerTime(19, 50)),
      ];

      final contexts = PlannerEngine.buildDailyContexts(
        prayers: prayers,
        blocks: const [],
        date: wednesday,
      );

      expect(contexts.every((c) => c.tag == PrayerTag.atHome), isTrue);
    });

    test('testWeekdayFiltering', () {
      final sunday = DateTime(2026, 6, 21);
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: DateTime(2026, 6, 21, 12, 30),
        blocks: [blockA()],
        date: sunday,
      );

      expect(context.tag, PrayerTag.atHome);
    });

    test('testPrayerAtBlockStartIsAtLocation', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: prayerTime(8, 0),
        blocks: [blockA()],
        date: wednesday,
      );
      expect(context.tag, PrayerTag.atLocation);
    });

    test('testPrayerAtBlockEndIsAtLocation', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Asr',
        prayerTime: prayerTime(14, 0),
        blocks: [blockA()],
        date: wednesday,
      );
      expect(context.tag, PrayerTag.atLocation);
    });

    test('testSixteenMinBeforeBlockEndIsNotTransition', () {
      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Asr',
        prayerTime: prayerTime(13, 44),
        blocks: [blockA()],
        date: wednesday,
      );
      expect(context.tag, PrayerTag.atLocation);
    });

    test('testOverlappingBlocksUsesFirstMatch', () {
      final early = const RoutineBlock(
        id: 'early',
        title: 'Early Class',
        location: 'Campus A',
        startTime: TimeOfDay(hour: 8, minute: 0),
        endTime: TimeOfDay(hour: 12, minute: 0),
        daysOfWeek: [0, 1, 2, 3, 4],
        color: Color(0xFF2196F3),
      );
      final late = const RoutineBlock(
        id: 'late',
        title: 'Late Class',
        location: 'Campus B',
        startTime: TimeOfDay(hour: 11, minute: 0),
        endTime: TimeOfDay(hour: 14, minute: 0),
        daysOfWeek: [0, 1, 2, 3, 4],
        color: Color(0xFF4CAF50),
      );

      final context = PlannerEngine.classifyPrayer(
        prayerName: 'Dhuhr',
        prayerTime: prayerTime(11, 30),
        blocks: [early, late],
        date: wednesday,
      );

      expect(context.tag, PrayerTag.atLocation);
      expect(context.blockTitle, 'Early Class');
    });
  });
}
