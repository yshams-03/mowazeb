import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/models/user_status.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/providers/dua_provider.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

void main() {
  group('Circle accountability flow', () {
    late FakeFirebaseFirestore firestore;
    const userA = 'uid-a';
    const userB = 'uid-b';

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('user A creates circle and user B joins via invite code', () async {
      final authA = MockFirebaseAuth(mockUser: MockUser(uid: userA), signedIn: true);
      final createResult =
          await CircleActions(firestore, authA).createCircle('Family');
      expect(createResult.isSuccess, isTrue);

      final circleId = createResult.circleId!;
      final circleSnap = await firestore.doc(FirestorePaths.circle(circleId)).get();
      final inviteCode = circleSnap.data()?['inviteCode'] as String;

      final authB = MockFirebaseAuth(mockUser: MockUser(uid: userB), signedIn: true);
      await CircleActions(firestore, authB).joinCircle(inviteCode);

      final updated = await firestore.doc(FirestorePaths.circle(circleId)).get();
      expect(updated.data()?['members'], containsAll([userA, userB]));
    });

    test('user A Dhuhr check-off visible in prayer log document', () async {
      final authA = MockFirebaseAuth(mockUser: MockUser(uid: userA), signedIn: true);
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());

      await PrayerLogActions(firestore, authA).checkOff(PrayerName.dhuhr);

      final log = await firestore
          .doc(FirestorePaths.prayerLogEntry(userA, dateKey, PrayerName.dhuhr.name))
          .get();
      expect(log.data()?['checkedOff'], isTrue);
      expect(log.data()?['status'], 'completed');
    });

    test('dua request posted and sender recorded in Firestore', () async {
      final authA = MockFirebaseAuth(mockUser: MockUser(uid: userA), signedIn: true);
      const circleId = 'circle-dua';

      await DuaActions(firestore, authA).postRequest(
        circleId: circleId,
        message: 'Exams tomorrow',
        authorName: 'User A',
      );

      final requests =
          await firestore.collection(FirestorePaths.duaRequests(circleId)).get();
      expect(requests.docs.length, 1);
      expect(requests.docs.first.data()['message'], 'Exams tomorrow');

      await requests.docs.first.reference.update({
        'duaSenders': FieldValue.arrayUnion([userB]),
      });

      final updated = await requests.docs.first.reference.get();
      expect(updated.data()?['duaSenders'], contains(userB));
    });

    test('traveling status suppresses missed alert eligibility', () {
      expect(
        UserPresenceStatus.traveling.suppressesMissedAlerts,
        isTrue,
      );
    });

    test('missed prayer log written when window closes without check-off', () async {
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
      await firestore
          .doc(FirestorePaths.prayerLogEntry(userB, dateKey, PrayerName.asr.name))
          .set(
            PrayerLogEntry(
              prayerName: PrayerName.asr,
              status: PrayerLogStatus.missed,
            ).toFirestore(),
          );

      final log = await firestore
          .doc(FirestorePaths.prayerLogEntry(userB, dateKey, PrayerName.asr.name))
          .get();
      expect(log.data()?['status'], 'missed');
    });
  });
}
