import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/dua_request.dart';

void main() {
  group('DuaRequest', () {
    test('fromFirestore parses fields', () {
      final request = DuaRequest.fromFirestore('req-1', {
        'authorUid': 'uid-a',
        'authorName': 'Ahmed',
        'message': 'Dua for my exam',
        'createdAt': '2026-06-21T10:00:00.000',
        'duaSenders': ['uid-b', 'uid-c'],
      });

      expect(request.id, 'req-1');
      expect(request.authorName, 'Ahmed');
      expect(request.message, 'Dua for my exam');
      expect(request.duaSenders, ['uid-b', 'uid-c']);
    });

    test('hasSentDua detects sender uid', () {
      final request = DuaRequest(
        id: 'req-1',
        authorUid: 'uid-a',
        authorName: 'Ahmed',
        message: 'Test',
        createdAt: DateTime(2026, 6, 21),
        duaSenders: const ['uid-b'],
      );

      expect(request.hasSentDua('uid-b'), isTrue);
      expect(request.hasSentDua('uid-x'), isFalse);
    });

    test('fromFirestore parses timestamp values', () {
      final createdAt = DateTime(2026, 6, 21, 11, 15);

      final request = DuaRequest.fromFirestore('req-2', {
        'authorUid': 'uid-z',
        'authorName': 'Fatima',
        'message': 'Please make dua',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(request.createdAt, createdAt);
      expect(request.authorUid, 'uid-z');
    });

    test('fromFirestore uses safe defaults for missing fields', () {
      final request = DuaRequest.fromFirestore('req-3', const {});

      expect(request.authorUid, '');
      expect(request.authorName, 'Member');
      expect(request.message, '');
      expect(request.duaSenders, isEmpty);
    });

    test('toFirestore keeps message and sender list', () {
      final request = DuaRequest(
        id: 'req-4',
        authorUid: 'uid-a',
        authorName: 'Ahmed',
        message: 'Remember my family in your duas',
        createdAt: DateTime(2026, 6, 21),
        duaSenders: const ['uid-b', 'uid-c'],
      );

      final data = request.toFirestore();

      expect(data['authorUid'], 'uid-a');
      expect(data['authorName'], 'Ahmed');
      expect(data['message'], 'Remember my family in your duas');
      expect(data['duaSenders'], ['uid-b', 'uid-c']);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
