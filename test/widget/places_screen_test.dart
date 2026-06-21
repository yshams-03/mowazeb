import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/screens/places_screen.dart';

import '../helpers/test_helpers.dart';

Future<void> pumpPlacesScreen(
  WidgetTester tester, {
  required FakeFirebaseFirestore firestore,
  required MockFirebaseAuth auth,
}) async {
  setLargeScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        firestoreProvider.overrideWithValue(firestore),
        firebaseAuthProvider.overrideWithValue(auth),
        noopHomeSeederOverride(),
      ],
      child: const PlacesScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('PlacesScreen', () {
    testWidgets('testPlacesListRenders', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-list';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      for (final entry in [
        testSavedLocation(id: '1', name: 'Home'),
        testSavedLocation(id: '2', name: 'Work', kind: LocationKind.work),
        testSavedLocation(id: '3', name: 'University'),
      ]) {
        await firestore
            .doc(FirestorePaths.savedLocation(uid, entry.id))
            .set(entry.toMap());
      }

      await pumpPlacesScreen(tester, firestore: firestore, auth: auth);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('University'), findsOneWidget);
    });

    testWidgets('testEmptyState', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-empty'),
        signedIn: true,
      );

      await pumpPlacesScreen(tester, firestore: firestore, auth: auth);

      expect(find.text('No saved places yet'), findsOneWidget);
      expect(find.text('Tap + to add your first place.'), findsOneWidget);
    });

    testWidgets('testTapPlaceOpensEditSheet', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-edit';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final location = testSavedLocation(id: '1', name: 'University');
      await firestore
          .doc(FirestorePaths.savedLocation(uid, location.id))
          .set(location.toMap());

      await pumpPlacesScreen(tester, firestore: firestore, auth: auth);
      await tester.tap(find.text('University'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Place'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('testDeleteConfirmationDialog', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-del';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final location = testSavedLocation(id: '1', name: 'University');
      await firestore
          .doc(FirestorePaths.savedLocation(uid, location.id))
          .set(location.toMap());

      await pumpPlacesScreen(tester, firestore: firestore, auth: auth);
      expect(find.text('University'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete place?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('University'), findsNothing);
    });
  });
}
