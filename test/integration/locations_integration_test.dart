import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/locations/models/location_suggestion.dart';
import 'package:ummah_pulse/features/locations/services/location_search_service.dart';
import 'package:ummah_pulse/features/locations/widgets/add_place_sheet.dart';
import 'package:ummah_pulse/features/planner/widgets/add_block_sheet.dart';
import 'package:ummah_pulse/features/locations/screens/places_screen.dart';

import '../helpers/test_helpers.dart';

class _StubSearchService extends LocationSearchService {
  @override
  Future<List<LocationSuggestion>> search(
    String query, {
    double? biasLat,
    double? biasLng,
    String? nearCity,
  }) async {
    return const [
      LocationSuggestion(
        displayName: 'AAST Alexandria, Egypt',
        shortName: 'AAST Alexandria',
        address: 'AAST Alexandria, Egypt',
        latitude: 31.3069,
        longitude: 30.0606,
      ),
    ];
  }
}

void main() {
  group('Locations integration', () {
    testWidgets('testSaveLocationPersistsToFirestore', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-save';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            locationSearchServiceOverride(_StubSearchService()),
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
            noopHomeSeederOverride(),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AddPlaceSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.tap(find.text('AAST Alexandria'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'My University');
      await tester.tap(find.text('Other'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Place'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final docs = await firestore.collection(FirestorePaths.savedLocations(uid)).get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['name'], 'My University');
      expect(docs.docs.first.data()['kind'], 'other');
    });

    testWidgets('testSavedLocationAppearsInPlacesTab', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-tab';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await firestore.doc(FirestorePaths.savedLocation(uid, '1')).set(
        testSavedLocation(id: '1', name: 'Home').toMap(),
      );
      await firestore.doc(FirestorePaths.savedLocation(uid, '2')).set(
        testSavedLocation(id: '2', name: 'University').toMap(),
      );

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
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Home'), findsWidgets);
      expect(find.text('University'), findsWidgets);
    });

    testWidgets('testSavedLocationAppearsInPlannerBlockPicker', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            savedLocationsOverride([
              testSavedLocation(id: '1', name: 'Home'),
              testSavedLocation(id: '2', name: 'University'),
            ]),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AddBlockSheet.show(context),
                child: const Text('Open Block'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Block'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('University'), findsWidgets);
    });

    testWidgets('testDeleteLocationRemovesFromUI', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-del-ui';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await firestore.doc(FirestorePaths.savedLocation(uid, '1')).set(
        testSavedLocation(id: '1', name: 'University').toMap(),
      );

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
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('University'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('University'), findsNothing);
    });
  });
}
