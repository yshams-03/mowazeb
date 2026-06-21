import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/locations/models/location_suggestion.dart';
import 'package:ummah_pulse/features/locations/services/location_search_service.dart';
import 'package:ummah_pulse/features/locations/widgets/add_place_sheet.dart';

import '../helpers/test_helpers.dart';

Finder searchFieldFinder() => find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search for a place...',
    );

class _StubSearchService extends LocationSearchService {
  _StubSearchService(this._results)
      : super(enableKnownPlaces: false, enableGeocodingFallback: false);

  final List<LocationSuggestion> _results;

  @override
  Future<List<LocationSuggestion>> search(
    String query, {
    double? biasLat,
    double? biasLng,
    String? nearCity,
  }) async {
    if (query.trim().length < 2) return [];
    return _results;
  }
}

void main() {
  final suggestions = [
    const LocationSuggestion(
      displayName: 'AAST Alexandria, Egypt',
      shortName: 'AAST Alexandria',
      address: 'AAST Alexandria, Egypt',
      latitude: 31.3069,
      longitude: 30.0606,
    ),
    const LocationSuggestion(
      displayName: 'AAST Campus, Abu Qir, Egypt',
      shortName: 'AAST Campus',
      address: 'AAST Campus, Abu Qir, Egypt',
      latitude: 31.31,
      longitude: 30.06,
    ),
    const LocationSuggestion(
      displayName: 'AAST Main Gate, Egypt',
      shortName: 'AAST Main Gate',
      address: 'AAST Main Gate, Egypt',
      latitude: 31.30,
      longitude: 30.05,
    ),
  ];

  Future<void> openSheet(WidgetTester tester, {FakeFirebaseFirestore? firestore}) async {
    setLargeScreen(tester);
    final fs = firestore ?? FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'uid-places'),
      signedIn: true,
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          firestoreProvider.overrideWithValue(fs),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          locationSearchServiceOverride(_StubSearchService(suggestions)),
          userSettingsProvider.overrideWith(
            (ref) => Stream.value(cairoSettings()),
          ),
          noopHomeSeederOverride(),
        ],
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => AddPlaceSheet.show(context),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('AddPlaceSheet', () {
    testWidgets('testPickOnMapAndSearchButtonsVisible', (tester) async {
      await openSheet(tester);
      expect(find.text('Pick on Map'), findsOneWidget);
      expect(find.text('Search by Name'), findsOneWidget);
      expect(find.text('How do you want to find this place?'), findsOneWidget);
    });

    testWidgets('testSearchFieldIsPresent', (tester) async {
      await openSheet(tester);
      expect(searchFieldFinder(), findsOneWidget);
      expect(find.text('Add Place'), findsOneWidget);
    });

    testWidgets('testTypingShowsSuggestions', (tester) async {
      await openSheet(tester);
      await tester.enterText(searchFieldFinder(), 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      expect(find.text('AAST Alexandria'), findsOneWidget);
      expect(find.text('AAST Campus'), findsOneWidget);
      expect(find.text('AAST Main Gate'), findsOneWidget);
    });

    testWidgets('testPickingSuggestionShowsNameField', (tester) async {
      await openSheet(tester);
      await tester.enterText(searchFieldFinder(), 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      await tester.tap(find.text('AAST Alexandria'));
      await tester.pump();

      expect(find.text('Label for this place'), findsOneWidget);
      expect(find.text('AAST Alexandria'), findsWidgets);
    });

    testWidgets('testSaveButtonDisabledUntilComplete', (tester) async {
      await openSheet(tester);
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Place');
      final button = tester.widget<ElevatedButton>(saveButton);
      expect(button.onPressed, isNull);

      await tester.enterText(searchFieldFinder(), 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.tap(find.text('AAST Alexandria'));
      await tester.pump();

      final enabledButton = tester.widget<ElevatedButton>(saveButton);
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('testKindChipsAllVisible', (tester) async {
      await openSheet(tester);
      await tester.enterText(searchFieldFinder(), 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.tap(find.text('AAST Alexandria'));
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('testSaveCallsFirestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await openSheet(tester, firestore: firestore);

      await tester.enterText(searchFieldFinder(), 'aast');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.tap(find.text('AAST Alexandria'));
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'My University');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Place'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final docs = await firestore
          .collection(FirestorePaths.savedLocations('uid-places'))
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['name'], 'My University');
    });

    testWidgets('testEditPlaceUpdatesFirestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-edit-save';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final location = testSavedLocation(id: '1', name: 'University');
      await firestore
          .doc(FirestorePaths.savedLocation(uid, location.id))
          .set(location.toMap());

      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            noopHomeSeederOverride(),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      AddPlaceSheet.show(context, existingLocation: location),
                  child: const Text('Open Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'e.g. University, Gym, Office...',
        ),
        'My University',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final doc = await firestore
          .doc(FirestorePaths.savedLocation(uid, '1'))
          .get();
      expect(doc.data()?['name'], 'My University');
    });
  });
}
