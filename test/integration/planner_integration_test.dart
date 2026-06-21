import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/planner/models/routine_block.dart';
import 'package:ummah_pulse/features/planner/providers/planner_provider.dart';
import 'package:ummah_pulse/features/planner/screens/planner_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Planner integration', () {
    testWidgets('testPlannerEngineTagsApplyToUI', (tester) async {
      setLargeScreen(tester);
      final wednesday = DateTime(2026, 6, 24);
      final contexts = testPrayerContexts(date: wednesday);
      final dhuhrContext = contexts.firstWhere((c) => c.prayerName == 'Dhuhr');

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [testRoutineBlock(title: 'University')],
                todayContexts: contexts,
                isLoading: false,
              ),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(dhuhrContext.displayTag, contains('University'));
      expect(find.textContaining('University'), findsWidgets);
    });

    testWidgets('testAddRoutineBlockSavesToFirestore', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-planner';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            savedLocationsOverride([
              testSavedLocation(id: 'loc-1', name: 'Gym'),
            ]),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      const block = RoutineBlock(
                        id: '',
                        title: 'Gym',
                        location: 'Gym',
                        locationId: 'loc-1',
                        startTime: TimeOfDay(hour: 16, minute: 0),
                        endTime: TimeOfDay(hour: 17, minute: 30),
                        daysOfWeek: [0],
                        color: Color(0xFF0D9488),
                      );
                      await ref.read(plannerProvider.notifier).addBlock(block);
                    },
                    child: const Text('Save Gym'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Save Gym'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final docs =
          await firestore.collection(FirestorePaths.routineBlocks(uid)).get();
      expect(docs.docs.length, 1);
      expect(docs.docs.first.data()['title'], 'Gym');
    });

    testWidgets('testDeleteRoutineBlock', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-del-block';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      await firestore.doc(FirestorePaths.routineBlock(uid, 'block-1')).set(
        testRoutineBlock(id: 'block-1', title: 'Gym').toFirestore(),
      );

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
                    onPressed: () =>
                        ref.read(plannerProvider.notifier).deleteBlock('block-1'),
                    child: const Text('Delete Block'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete Block'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final docs =
          await firestore.collection(FirestorePaths.routineBlocks(uid)).get();
      expect(docs.docs.length, 0);
    });
  });
}
