import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

void main() {
  group('todayPrayerLogsProvider', () {
    test('returns empty map when signed out', () async {
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth(signedIn: false)),
        ],
      );
      addTearDown(container.dispose);

      final logs = await container.read(todayPrayerLogsProvider.future);
      expect(logs, isEmpty);
    });

    test('streams completed entries from Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-logs';
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());

      await firestore
          .doc(FirestorePaths.prayerLogEntry(uid, dateKey, PrayerName.fajr.name))
          .set(PrayerLogEntry.completed(PrayerName.fajr).toFirestore());

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final logs = await container.read(todayPrayerLogsProvider.future);

      expect(logs[PrayerName.fajr]?.checkedOff, isTrue);
      expect(logs[PrayerName.dhuhr]?.checkedOff, isFalse);
    });
  });

  group('PrayerLogActions', () {
    test('checkOff writes completed entry for signed-in user', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-check';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid),
        signedIn: true,
      );
      final actions = PrayerLogActions(firestore, auth);

      await actions.checkOff(PrayerName.maghrib);

      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
      final doc = await firestore
          .doc(FirestorePaths.prayerLogEntry(uid, dateKey, PrayerName.maghrib.name))
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['checkedOff'], isTrue);
      expect(doc.data()?['status'], PrayerLogStatus.completed.value);
    });

    test('checkOff no-ops when signed out', () async {
      final firestore = FakeFirebaseFirestore();
      final actions = PrayerLogActions(firestore, MockFirebaseAuth(signedIn: false));

      await actions.checkOff(PrayerName.isha);

      final snap = await firestore.collection('users').get();
      expect(snap.docs, isEmpty);
    });
  });

  group('PrayerLogNotifier', () {
    test('checkOff updates state optimistically', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-notifier';
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(todayPrayerLogsProvider.future);

      await container.read(prayerLogNotifierProvider.notifier).checkOff(PrayerName.asr);

      expect(
        container.read(prayerLogNotifierProvider)[PrayerName.asr]?.checkedOff,
        isTrue,
      );
    });
  });
}
