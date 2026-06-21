import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/user_status.dart';
import 'package:ummah_pulse/features/community/providers/status_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/profile/screens/profile_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('loads and shows user email', (tester) async {
      setLargeScreen(tester);
      final auth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'uid-profile',
          email: 'ali@test.com',
          displayName: 'Ali',
        ),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(auth),
            userSettingsProvider.overrideWith((ref) => Stream.value(cairoSettings())),
            savedLocationsOverride(const []),
            currentUserStatusProvider.overrideWith(
              (ref) => Stream.value(const UserStatus()),
            ),
            noopHomeSeederOverride(),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('ali@test.com'), findsOneWidget);
      expect(find.text('Save Home Address'), findsOneWidget);
    });

    testWidgets('prefills home from saved home location', (tester) async {
      setLargeScreen(tester);
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-profile', email: 'ali@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(auth),
            userSettingsProvider.overrideWith((ref) => Stream.value(cairoSettings())),
            savedLocationsOverride([
              testSavedLocation(
                id: 'home',
                name: 'My Cairo Home',
                kind: LocationKind.home,
              ),
            ]),
            currentUserStatusProvider.overrideWith(
              (ref) => Stream.value(const UserStatus()),
            ),
            noopHomeSeederOverride(),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('My Cairo Home'), findsOneWidget);
    });

    testWidgets('save home address writes to Firestore', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-save', email: 'ali@test.com'),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            userSettingsProvider.overrideWith((ref) => Stream.value(cairoSettings())),
            savedLocationsOverride(const []),
            currentUserStatusProvider.overrideWith(
              (ref) => Stream.value(const UserStatus()),
            ),
            noopHomeSeederOverride(),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(TextField), '123 Main St');
      await tester.tap(find.text('Save Home Address'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final doc = await firestore.doc('users/uid-save/settings/preferences').get();
      expect(doc.data()?['homeAddress'], '123 Main St');
      expect(find.text('Home address saved.'), findsOneWidget);
    });
  });
}
