import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

/// End-to-end auth → onboarding prefs → prayer log flow (Firestore-backed).
void main() {
  group('Auth to prayer flow', () {
    test('registers user settings and prayer check-off in Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-flow';

      await firestore.doc(FirestorePaths.userSettings(uid)).set(
        cairoSettings().toFirestore(),
      );

      final settingsSnap = await firestore.doc(FirestorePaths.userSettings(uid)).get();
      expect(settingsSnap.data()?['onboardingComplete'], isTrue);
      expect(settingsSnap.data()?['latitude'], isNotNull);

      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
      await firestore
          .doc(FirestorePaths.prayerLogEntry(uid, dateKey, PrayerName.dhuhr.name))
          .set(PrayerLogEntry.completed(PrayerName.dhuhr).toFirestore());

      final logSnap = await firestore
          .doc(FirestorePaths.prayerLogEntry(uid, dateKey, PrayerName.dhuhr.name))
          .get();
      expect(logSnap.data()?['checkedOff'], isTrue);
      expect(logSnap.data()?['status'], 'completed');
    });

    test('create circle writes lookup and member settings', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-circle-flow';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      final actions = CircleActions(firestore, auth);
      final result = await actions.createCircle('Family');

      expect(result.isSuccess, isTrue);
      final circle = await firestore.doc(FirestorePaths.circle(result.circleId!)).get();
      expect(circle.data()?['members'], [uid]);
    });
  });
}
