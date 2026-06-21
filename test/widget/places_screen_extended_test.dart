import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/screens/places_screen.dart';

import '../helpers/test_helpers.dart';

Future<void> pumpPlaces(
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
  group('PlacesScreen extended', () {
    testWidgets('shows distinct kind emojis for home work and other', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-icons';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      final locations = [
        testSavedLocation(id: 'h', name: 'Home', kind: LocationKind.home),
        testSavedLocation(id: 'w', name: 'Work', kind: LocationKind.work),
        testSavedLocation(id: 'o', name: 'Gym', kind: LocationKind.other),
      ];
      for (final loc in locations) {
        await firestore
            .doc(FirestorePaths.savedLocation(uid, loc.id))
            .set(loc.toMap());
      }

      await pumpPlaces(tester, firestore: firestore, auth: auth);

      expect(find.text('🏠'), findsOneWidget);
      expect(find.text('💼'), findsOneWidget);
      expect(find.text('📍'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('FAB opens add place sheet', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-fab'),
        signedIn: true,
      );

      await pumpPlaces(tester, firestore: firestore, auth: auth);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Place'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('cancel delete keeps location card', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-cancel-del';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final location = testSavedLocation(id: '1', name: 'University');
      await firestore
          .doc(FirestorePaths.savedLocation(uid, location.id))
          .set(location.toMap());

      await pumpPlaces(tester, firestore: firestore, auth: auth);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('University'), findsOneWidget);
    });
  });
}
