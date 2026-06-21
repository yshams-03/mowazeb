import 'package:cloud_firestore/cloud_firestore.dart';

import '../../prayer/models/prayer_time_model.dart';
import 'user_status.dart';

enum PrayerLogStatus {
  pending('pending'),
  completed('completed'),
  missed('missed'),
  excused('excused');

  const PrayerLogStatus(this.value);
  final String value;

  static PrayerLogStatus parse(String? raw) {
    return PrayerLogStatus.values.firstWhere(
      (status) => status.value == raw,
      orElse: () => PrayerLogStatus.pending,
    );
  }
}

class PrayerLogEntry {
  const PrayerLogEntry({
    required this.prayerName,
    this.checkedOff = false,
    this.checkedAt,
    this.status = PrayerLogStatus.pending,
  });

  final PrayerName prayerName;
  final bool checkedOff;
  final DateTime? checkedAt;
  final PrayerLogStatus status;

  factory PrayerLogEntry.fromFirestore(PrayerName prayerName, Map<String, dynamic>? data) {
    if (data == null) {
      return PrayerLogEntry(prayerName: prayerName);
    }

    final checkedAtRaw = data['checkedAt'];
    DateTime? checkedAt;
    if (checkedAtRaw is Timestamp) {
      checkedAt = checkedAtRaw.toDate();
    } else if (checkedAtRaw is String) {
      checkedAt = DateTime.tryParse(checkedAtRaw);
    }

    return PrayerLogEntry(
      prayerName: prayerName,
      checkedOff: data['checkedOff'] as bool? ?? false,
      checkedAt: checkedAt,
      status: PrayerLogStatus.parse(data['status'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'checkedOff': checkedOff,
      'status': status.value,
      if (checkedAt != null) 'checkedAt': Timestamp.fromDate(checkedAt!),
    };
  }

  PrayerLogEntry copyWith({
    bool? checkedOff,
    DateTime? checkedAt,
    PrayerLogStatus? status,
  }) {
    return PrayerLogEntry(
      prayerName: prayerName,
      checkedOff: checkedOff ?? this.checkedOff,
      checkedAt: checkedAt ?? this.checkedAt,
      status: status ?? this.status,
    );
  }

  static PrayerLogEntry completed(PrayerName prayerName, {DateTime? checkedAt}) {
    final at = checkedAt ?? DateTime.now();
    return PrayerLogEntry(
      prayerName: prayerName,
      checkedOff: true,
      checkedAt: at,
      status: PrayerLogStatus.completed,
    );
  }
}

class MemberPrayerFeed {
  const MemberPrayerFeed({
    required this.uid,
    required this.displayName,
    required this.entries,
    this.isCurrentUser = false,
    this.presenceStatus = UserPresenceStatus.active,
  });

  final String uid;
  final String displayName;
  final Map<PrayerName, PrayerLogEntry> entries;
  final bool isCurrentUser;
  final UserPresenceStatus presenceStatus;
}
