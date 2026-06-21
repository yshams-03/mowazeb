import 'package:flutter/material.dart';

class RoutineBlock {
  const RoutineBlock({
    required this.id,
    required this.title,
    required this.location,
    this.locationId,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    required this.color,
  });

  final String id;
  final String title;
  final String location;
  final String? locationId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> daysOfWeek;
  final Color color;

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  bool appliesOnWeekday(int weekdayIndex) => daysOfWeek.contains(weekdayIndex);

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      if (locationId != null) 'locationId': locationId,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'daysOfWeek': daysOfWeek,
      'colorValue': color.toARGB32(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory RoutineBlock.fromFirestore(String id, Map<String, dynamic> data) {
    return RoutineBlock(
      id: id,
      title: data['title'] as String? ?? '',
      location: data['location'] as String? ?? '',
      locationId: data['locationId'] as String?,
      startTime: TimeOfDay(
        hour: data['startHour'] as int? ?? 9,
        minute: data['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: data['endHour'] as int? ?? 17,
        minute: data['endMinute'] as int? ?? 0,
      ),
      daysOfWeek: (data['daysOfWeek'] as List<dynamic>? ?? [0, 1, 2, 3, 4])
          .map((d) => d as int)
          .toList(),
      color: Color(data['colorValue'] as int? ?? 0xFF0D9488),
    );
  }

  RoutineBlock copyWith({
    String? id,
    String? title,
    String? location,
    String? locationId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    Color? color,
  }) {
    return RoutineBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      locationId: locationId ?? this.locationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      color: color ?? this.color,
    );
  }
}

/// Preset block colors for the color picker.
class RoutineBlockColors {
  RoutineBlockColors._();

  static const List<Color> presets = [
    Color(0xFF0D9488),
    Color(0xFF1B8A6B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFD4A843),
    Color(0xFF64748B),
  ];
}
