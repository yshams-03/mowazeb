import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/community/screens/circle_detail_screen.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Community integration', () {
    testWidgets('testCreateCirclePersistsToFirestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-create';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await ref.read(circleActionsProvider).createCircle('Family');
                    },
                    child: const Text('Create'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final circles = await firestore.collection(FirestorePaths.circles()).get();
      expect(circles.docs.length, 1);
      expect(circles.docs.first.data()['name'], 'Family');
      expect(circles.docs.first.data()['members'], [uid]);
      expect(circles.docs.first.data()['inviteCode'], isNotEmpty);

      final lookup = await firestore
          .doc('circle_lookup/${circles.docs.first.data()['inviteCode']}')
          .get();
      expect(lookup.exists, isTrue);

      final settings =
          await firestore.doc(FirestorePaths.userSettings(uid)).get();
      expect(settings.data()?['circleIds'], [circles.docs.first.id]);
    });

    testWidgets('testJoinCircleAddsMember', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const creator = 'uid-creator';
      const joiner = 'uid-joiner';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: joiner), signedIn: true);

      await firestore.collection(FirestorePaths.circles()).doc('circle-1').set({
        'name': 'Family',
        'createdBy': creator,
        'members': [creator],
        'inviteCode': 'JOIN01',
        'groupStreak': 0,
      });
      await firestore.doc('circle_lookup/JOIN01').set({
        'circleId': 'circle-1',
        'createdBy': creator,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await ref.read(circleActionsProvider).joinCircle('JOIN01');
                    },
                    child: const Text('Join'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Join'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final circle = await firestore.doc(FirestorePaths.circle('circle-1')).get();
      expect(circle.data()?['members'], containsAll([creator, joiner]));
    });

    testWidgets('testPrayerCheckOffWritesToFirestore', (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-checkoff';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(prayerLogActionsProvider)
                          .checkOff(PrayerName.maghrib);
                    },
                    child: const Text('Check Off'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Check Off'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final doc = await firestore
          .doc(FirestorePaths.prayerLogEntry(uid, dateKey, PrayerName.maghrib.name))
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['checkedOff'], isTrue);
      expect(doc.data()?['status'], 'completed');
    });

    testWidgets('testCircleDetailShowsMemberFeed', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-feed';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await firestore.doc(FirestorePaths.circle('circle-1')).set({
        'name': 'Family',
        'createdBy': uid,
        'members': [uid, 'uid-other'],
        'inviteCode': 'FAM001',
        'groupStreak': 1,
      });

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            circleProvider('circle-1').overrideWith(
              (ref) => Stream.value(
                testCircle(
                  id: 'circle-1',
                  name: 'Family',
                  members: [uid, 'uid-other'],
                ),
              ),
            ),
            circleFeedProvider('circle-1').overrideWith(
              (ref) => Stream.value([
                testMemberFeed(displayName: 'You', isCurrentUser: true),
                testMemberFeed(
                  uid: 'uid-other',
                  displayName: 'Ahmed',
                  isCurrentUser: false,
                  entries: {
                    PrayerName.fajr: PrayerLogEntry.completed(PrayerName.fajr),
                    for (final prayer in PrayerName.values
                        .where((p) => p != PrayerName.fajr))
                      prayer: PrayerLogEntry(prayerName: prayer),
                  },
                ),
              ]),
            ),
          ],
          child: const CircleDetailScreen(circleId: 'circle-1'),
        ),
      );
      await tester.pump();

      expect(find.text("Today's prayer feed"), findsOneWidget);
      expect(find.textContaining('You'), findsWidgets);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
