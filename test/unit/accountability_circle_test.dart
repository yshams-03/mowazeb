import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/accountability_circle.dart';

void main() {
  group('AccountabilityCircle', () {
    test('fromFirestore parses all fields', () {
      final circle = AccountabilityCircle.fromFirestore('id-1', {
        'name': 'Family',
        'createdBy': 'uid-a',
        'members': ['uid-a', 'uid-b'],
        'inviteCode': 'XYZ789',
        'groupStreak': 5,
      });

      expect(circle.id, 'id-1');
      expect(circle.name, 'Family');
      expect(circle.createdBy, 'uid-a');
      expect(circle.members, ['uid-a', 'uid-b']);
      expect(circle.inviteCode, 'XYZ789');
      expect(circle.groupStreak, 5);
    });

    test('toFirestore includes required fields', () {
      const circle = AccountabilityCircle(
        id: 'id-1',
        name: 'Masjid Group',
        createdBy: 'uid-a',
        members: ['uid-a'],
        inviteCode: 'ABC123',
      );

      final data = circle.toFirestore();
      expect(data['name'], 'Masjid Group');
      expect(data['createdBy'], 'uid-a');
      expect(data['members'], ['uid-a']);
      expect(data['inviteCode'], 'ABC123');
      expect(data['groupStreak'], 0);
    });

    test('copyWith updates name and members', () {
      const circle = AccountabilityCircle(
        id: 'id-1',
        name: 'Old',
        createdBy: 'uid-a',
        members: ['uid-a'],
        inviteCode: 'ABC123',
      );

      final updated = circle.copyWith(
        name: 'New',
        members: ['uid-a', 'uid-b'],
      );

      expect(updated.name, 'New');
      expect(updated.members, ['uid-a', 'uid-b']);
      expect(updated.inviteCode, 'ABC123');
    });
  });
}
