import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/providers/dua_provider.dart';

void main() {
  group('DuaActions', () {
    test('postRequest writes dua document', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-dua';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, displayName: 'Ali'),
        signedIn: true,
      );
      final actions = DuaActions(firestore, auth);

      await actions.postRequest(
        circleId: 'circle1',
        message: '  Please make Dua for my exam  ',
        authorName: 'Ali',
      );

      final snap = await firestore
          .collection(FirestorePaths.duaRequests('circle1'))
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['message'], 'Please make Dua for my exam');
      expect(snap.docs.first.data()['authorUid'], uid);
      expect(snap.docs.first.data()['authorName'], 'Ali');
    });

    test('postRequest no-ops for empty message or signed-out user', () async {
      final firestore = FakeFirebaseFirestore();
      final signedOut = DuaActions(firestore, MockFirebaseAuth(signedIn: false));
      final signedIn = DuaActions(
        firestore,
        MockFirebaseAuth(mockUser: MockUser(uid: 'uid'), signedIn: true),
      );

      await signedOut.postRequest(
        circleId: 'circle1',
        message: 'Hello',
        authorName: 'Ali',
      );
      await signedIn.postRequest(
        circleId: 'circle1',
        message: '   ',
        authorName: 'Ali',
      );

      final snap = await firestore
          .collection(FirestorePaths.duaRequests('circle1'))
          .get();
      expect(snap.docs, isEmpty);
    });
  });

  group('duaRequestsProvider', () {
    test('streams requests for a circle', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection(FirestorePaths.duaRequests('circle1')).add({
        'authorUid': 'uid-a',
        'authorName': 'Ali',
        'message': 'Make dua',
        'createdAt': DateTime(2026, 6, 21),
        'duaSenders': <String>[],
      });

      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final requests = await container.read(duaRequestsProvider('circle1').future);

      expect(requests.length, 1);
      expect(requests.first.message, 'Make dua');
    });
  });
}
