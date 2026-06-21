import 'package:cloud_firestore/cloud_firestore.dart';

enum UserPresenceStatus {
  active('active'),
  traveling('traveling'),
  excused('excused'),
  inExam('in_exam');

  const UserPresenceStatus(this.value);
  final String value;

  static UserPresenceStatus parse(String? raw) {
    return UserPresenceStatus.values.firstWhere(
      (status) => status.value == raw,
      orElse: () => UserPresenceStatus.active,
    );
  }

  /// Public label shown to circle members — never includes a private reason.
  String get publicLabel {
    switch (this) {
      case UserPresenceStatus.active:
        return 'Active';
      case UserPresenceStatus.traveling:
        return '✈️ Traveling';
      case UserPresenceStatus.excused:
        return '🤲 Excused';
      case UserPresenceStatus.inExam:
        return '📚 In Exam';
    }
  }

  bool get suppressesMissedAlerts => this != UserPresenceStatus.active;
}

class UserStatus {
  const UserStatus({
    this.current = UserPresenceStatus.active,
    this.expiresAt,
  });

  final UserPresenceStatus current;
  final DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  UserPresenceStatus get effectiveStatus =>
      isExpired ? UserPresenceStatus.active : current;

  factory UserStatus.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const UserStatus();

    final expiresRaw = data['expiresAt'];
    DateTime? expiresAt;
    if (expiresRaw is Timestamp) {
      expiresAt = expiresRaw.toDate();
    } else if (expiresRaw is String) {
      expiresAt = DateTime.tryParse(expiresRaw);
    }

    return UserStatus(
      current: UserPresenceStatus.parse(data['current'] as String?),
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'current': current.value,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserStatus copyWith({
    UserPresenceStatus? current,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return UserStatus(
      current: current ?? this.current,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }
}
