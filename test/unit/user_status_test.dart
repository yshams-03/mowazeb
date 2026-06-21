import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/user_status.dart';

void main() {
  group('UserStatus', () {
    test('effectiveStatus returns active when expired', () {
      final status = UserStatus(
        current: UserPresenceStatus.traveling,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(status.effectiveStatus, UserPresenceStatus.active);
    });

    test('publicLabel never exposes private reason for excused', () {
      expect(
        UserPresenceStatus.excused.publicLabel,
        '🤲 Excused',
      );
      expect(
        UserPresenceStatus.excused.publicLabel.contains('reason'),
        isFalse,
      );
    });

    test('suppressesMissedAlerts for non-active statuses', () {
      expect(UserPresenceStatus.active.suppressesMissedAlerts, isFalse);
      expect(UserPresenceStatus.traveling.suppressesMissedAlerts, isTrue);
      expect(UserPresenceStatus.inExam.suppressesMissedAlerts, isTrue);
    });

    test('parse falls back to active for null or unknown values', () {
      expect(UserPresenceStatus.parse(null), UserPresenceStatus.active);
      expect(UserPresenceStatus.parse('unknown'), UserPresenceStatus.active);
    });

    test('fromFirestore parses timestamp and status', () {
      final expiresAt = DateTime(2026, 6, 21, 18, 0);

      final status = UserStatus.fromFirestore({
        'current': 'in_exam',
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      expect(status.current, UserPresenceStatus.inExam);
      expect(status.expiresAt, expiresAt);
    });

    test('copyWith can clear expiresAt', () {
      final status = UserStatus(
        current: UserPresenceStatus.excused,
        expiresAt: DateTime(2026, 6, 21, 12),
      );

      final updated = status.copyWith(clearExpiresAt: true);

      expect(updated.current, UserPresenceStatus.excused);
      expect(updated.expiresAt, isNull);
    });

    test('toFirestore includes current status and expiry timestamp', () {
      final expiresAt = DateTime(2026, 6, 21, 15, 30);
      final data = UserStatus(
        current: UserPresenceStatus.traveling,
        expiresAt: expiresAt,
      ).toFirestore();

      expect(data['current'], 'traveling');
      expect(data['expiresAt'], Timestamp.fromDate(expiresAt));
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
