import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/screens/circles_screen.dart';

import '../helpers/test_helpers.dart';

Future<void> pumpCirclesScreen(
  WidgetTester tester, {
  required FakeFirebaseFirestore firestore,
  required MockFirebaseAuth auth,
  List<Override> overrides = const [],
}) async {
  setLargeScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        firestoreProvider.overrideWithValue(firestore),
        firebaseAuthProvider.overrideWithValue(auth),
        ...overrides,
      ],
      child: const CirclesScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('CirclesScreen', () {
    testWidgets('shows empty state when user has no circles', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-empty'),
        signedIn: true,
      );

      await pumpCirclesScreen(tester, firestore: firestore, auth: auth);

      expect(find.text('No circles yet'), findsOneWidget);
      expect(find.text('Create Circle'), findsWidgets);
      expect(find.text('Join Circle'), findsWidgets);
    });

    testWidgets('lists user circles from Firestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-circles';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await firestore.collection('circles').doc('c1').set({
        'name': 'Family',
        'createdBy': uid,
        'members': [uid],
        'inviteCode': 'ABC123',
        'groupStreak': 2,
      });
      await firestore.collection('circles').doc('c2').set({
        'name': 'Work Friends',
        'createdBy': 'other',
        'members': [uid, 'other'],
        'inviteCode': 'XYZ789',
        'groupStreak': 0,
      });

      await pumpCirclesScreen(tester, firestore: firestore, auth: auth);

      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Work Friends'), findsOneWidget);
      expect(find.textContaining('2 members'), findsOneWidget);
    });
  });
}
