import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/accountability_circle.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/services/circle_invite_lookup.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CircleActions extended', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late CircleActions actions;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'testUid', displayName: 'Test User'),
        signedIn: true,
      );
      actions = CircleActions(firestore, auth);
    });

    test('createCircle rejects empty name', () async {
      final result = await actions.createCircle('   ');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Enter a circle name.');
    });

    test('createCircle rejects when user is not signed in', () async {
      final guestActions = CircleActions(
        firestore,
        MockFirebaseAuth(signedIn: false),
      );

      final result = await guestActions.createCircle('Family');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Sign in to create a circle.');
    });

    test('createCircle writes circle_lookup document', () async {
      final result = await actions.createCircle('Family');

      expect(result.isSuccess, isTrue);
      expect(result.inviteCode, matches(RegExp(r'^[A-Z0-9]{6}$')));

      final circleDoc =
          await firestore.doc(FirestorePaths.circle(result.circleId!)).get();
      final circle = AccountabilityCircle.fromFirestore(
        circleDoc.id,
        circleDoc.data()!,
      );
      expect(circle.name, 'Family');
      expect(circle.createdBy, 'testUid');
      expect(circle.members, contains('testUid'));

      final lookup = await firestore
          .doc(CircleInviteLookup.docPath(result.inviteCode!))
          .get();
      expect(lookup.exists, isTrue);
      expect(CircleInviteLookup.circleIdFrom(lookup.data()), result.circleId);
    });

    test('createCircle writes alphanumeric invite code', () async {
      final result = await actions.createCircle('Family');

      expect(result.isSuccess, isTrue);
      expect(result.inviteCode, matches(RegExp(r'^[A-Z0-9]{6}$')));

      final circleDoc =
          await firestore.doc(FirestorePaths.circle(result.circleId!)).get();
      final circle = AccountabilityCircle.fromFirestore(
        circleDoc.id,
        circleDoc.data()!,
      );
      expect(circle.name, 'Family');
      expect(circle.createdBy, 'testUid');
      expect(circle.members, contains('testUid'));
    });

    test('joinCircle does not duplicate existing member', () async {
      final created = await actions.createCircle('Study');
      expect(created.isSuccess, isTrue);

      final again = await actions.joinCircle(created.inviteCode!);

      expect(again, created.circleId);
      final doc = await firestore.doc(FirestorePaths.circle(created.circleId!)).get();
      final members = List<String>.from(doc.data()!['members'] as List);
      expect(members.where((m) => m == 'testUid').length, 1);
    });

    test('invite codes are unique across multiple creates', () async {
      final codes = <String>{};
      for (var i = 0; i < 5; i++) {
        final result = await actions.createCircle('Circle $i');
        expect(result.isSuccess, isTrue);
        codes.add(result.inviteCode!);
      }
      expect(codes.length, 5);
    });

    test('new circle has zero group streak', () async {
      final result = await actions.createCircle('NewGroup');
      final doc = await firestore.doc(FirestorePaths.circle(result.circleId!)).get();
      final circle = AccountabilityCircle.fromFirestore(doc.id, doc.data()!);
      expect(circle.groupStreak, 0);
    });
  });

  group('circleProvider', () {
    test('returns null for missing circle', () async {
      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(FakeFirebaseFirestore())],
      );
      addTearDown(container.dispose);

      final circle = await container.read(circleProvider('missing').future);
      expect(circle, isNull);
    });
  });

  group('userCirclesProvider extended', () {
    test('returns empty list when signed out', () async {
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth(signedIn: false)),
        ],
      );
      addTearDown(container.dispose);

      final circles = await container.read(userCirclesProvider.future);
      expect(circles, isEmpty);
    });

    test('excludes circles where user is not a member', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'testUid'),
        signedIn: true,
      );

      await firestore.collection(FirestorePaths.circles()).doc('c1').set(
        testCircle(id: 'c1', name: 'Mine', members: const ['testUid']).toFirestore(),
      );
      await firestore.collection(FirestorePaths.circles()).doc('c2').set(
        testCircle(
          id: 'c2',
          name: 'Other',
          members: const ['other'],
          inviteCode: 'OTH111',
        ).toFirestore(),
      );
      await firestore.collection(FirestorePaths.circles()).doc('c3').set(
        testCircle(
          id: 'c3',
          name: 'Also Mine',
          members: const ['testUid', 'friend'],
          inviteCode: 'ALM222',
        ).toFirestore(),
      );

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      final circles = await container.read(userCirclesProvider.future);

      expect(circles.map((c) => c.id), containsAll(['c1', 'c3']));
      expect(circles.map((c) => c.id), isNot(contains('c2')));
    });
  });

  group('joinCircle lookup path', () {
    test('joinCircle uses circle_lookup document', () async {
      final firestore = FakeFirebaseFirestore();
      const circleId = 'circle1';
      const code = 'JOIN01';

      await firestore.doc(FirestorePaths.circle(circleId)).set(
        testCircle(
          id: circleId,
          members: const ['otherUid'],
          inviteCode: code,
        ).toFirestore(),
      );
      await firestore.doc(CircleInviteLookup.docPath(code)).set(
        CircleInviteLookup.toFirestore(circleId: circleId, createdBy: 'otherUid'),
      );

      final joiner = CircleActions(
        firestore,
        MockFirebaseAuth(mockUser: MockUser(uid: 'testUid'), signedIn: true),
      );

      final joined = await joiner.joinCircle(code);
      expect(joined, circleId);

      final doc = await firestore.doc(FirestorePaths.circle(circleId)).get();
      expect(doc.data()?['members'], contains('testUid'));
    });
  });
}
