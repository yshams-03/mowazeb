import 'package:intl/intl.dart';

enum PrayerName {
  fajr('Fajr'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha');

  const PrayerName(this.displayName);
  final String displayName;
}

class PrayerTimeModel {
  const PrayerTimeModel({
    required this.name,
    required this.time,
    this.isNext = false,
    this.isPassed = false,
  });

  final PrayerName name;
  final DateTime time;
  final bool isNext;
  final bool isPassed;

  String get formattedTime => DateFormat.jm().format(time);

  String get compactFormattedTime => DateFormat('h:mm a').format(time);

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.displayName,
      'time': time.toIso8601String(),
    };
  }

  factory PrayerTimeModel.fromFirestore(Map<String, dynamic> data) {
    return PrayerTimeModel(
      name: PrayerName.values.firstWhere(
        (p) => p.displayName == data['name'],
        orElse: () => PrayerName.fajr,
      ),
      time: DateTime.parse(data['time'] as String),
    );
  }

  PrayerTimeModel copyWith({
    PrayerName? name,
    DateTime? time,
    bool? isNext,
    bool? isPassed,
  }) {
    return PrayerTimeModel(
      name: name ?? this.name,
      time: time ?? this.time,
      isNext: isNext ?? this.isNext,
      isPassed: isPassed ?? this.isPassed,
    );
  }
}

class PrayerDayLog {
  const PrayerDayLog({
    required this.date,
    required this.prayers,
    required this.latitude,
    required this.longitude,
    required this.calculationMethod,
    required this.madhab,
  });

  final String date;
  final List<PrayerTimeModel> prayers;
  final double latitude;
  final double longitude;
  final String calculationMethod;
  final String madhab;

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'prayers': prayers.map((p) => p.toFirestore()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'loggedAt': DateTime.now().toIso8601String(),
    };
  }
}
