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
  group('CircleActions', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late CircleActions actions;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-circles'), signedIn: true);
      actions = CircleActions(firestore, auth);
    });

    test('createCircle writes circle and circle_lookup', () async {
      final result = await actions.createCircle('Family Circle');

      expect(result.isSuccess, isTrue);
      expect(result.circleId, isNotNull);
      expect(result.inviteCode, isNotNull);
      expect(result.inviteCode!.length, 6);

      final circleDoc =
          await firestore.doc(FirestorePaths.circle(result.circleId!)).get();
      expect(circleDoc.exists, isTrue);

      final circle = AccountabilityCircle.fromFirestore(
        circleDoc.id,
        circleDoc.data()!,
      );
      expect(circle.name, 'Family Circle');
      expect(circle.createdBy, 'uid-circles');
      expect(circle.members, ['uid-circles']);
      expect(circle.inviteCode, result.inviteCode);

      final lookupDoc = await firestore
          .doc(CircleInviteLookup.docPath(result.inviteCode!))
          .get();
      expect(lookupDoc.exists, isTrue);
      expect(
        CircleInviteLookup.circleIdFrom(lookupDoc.data()),
        result.circleId,
      );

      final settingsDoc = await firestore
          .doc(FirestorePaths.userSettings('uid-circles'))
          .get();
      expect(settingsDoc.data()?['circleIds'], contains(result.circleId));
    });

    test('joinCircle succeeds with valid invite code', () async {
      final created = await actions.createCircle('Study Group');
      expect(created.isSuccess, isTrue);

      final otherAuth =
          MockFirebaseAuth(mockUser: MockUser(uid: 'uid-joiner'), signedIn: true);
      final joiner = CircleActions(firestore, otherAuth);

      final circleId = await joiner.joinCircle(created.inviteCode!);

      expect(circleId, created.circleId);

      final circleDoc =
          await firestore.doc(FirestorePaths.circle(circleId!)).get();
      final circle = AccountabilityCircle.fromFirestore(
        circleDoc.id,
        circleDoc.data()!,
      );
      expect(circle.members, containsAll(['uid-circles', 'uid-joiner']));
    });

    test('joinCircle returns null for invalid code', () async {
      final circleId = await actions.joinCircle('ZZZZZZ');

      expect(circleId, isNull);
    });

    test('joinCircle returns null for malformed code', () async {
      final circleId = await actions.joinCircle('ABC');

      expect(circleId, isNull);
    });
  });

  group('userCirclesProvider', () {
    test('streams signed-in user circles sorted by name', () async {
      final firestore = FakeFirebaseFirestore();
      final auth =
          MockFirebaseAuth(mockUser: MockUser(uid: 'uid-circles'), signedIn: true);

      await firestore.collection(FirestorePaths.circles()).doc('circle-z').set(
        testCircle(
          id: 'circle-z',
          name: 'Zakat Group',
          createdBy: 'uid-circles',
          members: const ['uid-circles'],
          inviteCode: 'ZAK123',
        ).toFirestore(),
      );
      await firestore.collection(FirestorePaths.circles()).doc('circle-a').set(
        testCircle(
          id: 'circle-a',
          name: 'Alpha Circle',
          createdBy: 'uid-circles',
          members: const ['uid-circles', 'uid-2'],
          inviteCode: 'ALP123',
        ).toFirestore(),
      );
      await firestore.collection(FirestorePaths.circles()).doc('circle-x').set(
        testCircle(
          id: 'circle-x',
          name: 'Outside Circle',
          createdBy: 'uid-other',
          members: const ['uid-other'],
          inviteCode: 'OUT123',
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

      expect(circles.map((circle) => circle.id), ['circle-a', 'circle-z']);
      expect(circles.map((circle) => circle.name), ['Alpha Circle', 'Zakat Group']);
    });

    test('returns empty list when user is signed out', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth(signedIn: false)),
        ],
      );
      addTearDown(container.dispose);

      final circles = await container.read(userCirclesProvider.future);

      expect(circles, isEmpty);
    });
  });
}
