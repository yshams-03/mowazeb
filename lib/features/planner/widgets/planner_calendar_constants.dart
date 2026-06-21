import '../models/routine_block.dart';

class PlannerCalendarConstants {
  PlannerCalendarConstants._();

  static const startHour = 5;
  static const endHour = 23;
  static const hourHeight = 52.0;
  static const dayColumnWidth = 88.0;

  static int get totalHours => endHour - startHour;
  static double get dayHeight => totalHours * hourHeight;

  static const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

double minutesToTopOffset(int minutes) {
  const startMinutes = PlannerCalendarConstants.startHour * 60;
  final clamped = minutes.clamp(
    PlannerCalendarConstants.startHour * 60,
    PlannerCalendarConstants.endHour * 60,
  );
  return ((clamped - startMinutes) / 60) * PlannerCalendarConstants.hourHeight;
}

double blockHeight(RoutineBlock block) {
  final durationMinutes = block.endMinutes - block.startMinutes;
  return (durationMinutes / 60) * PlannerCalendarConstants.hourHeight;
}

String formatHourLabel(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final display = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$display $period';
}
