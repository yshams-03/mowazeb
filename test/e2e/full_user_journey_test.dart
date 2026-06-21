import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/providers/dua_provider.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';
import 'package:ummah_pulse/features/planner/services/planner_engine.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

/// Simulates a full-day user journey using Firestore-backed actions (no device).
void main() {
  group('Full user journey (E2E simulation)', () {
    test('onboarding → places → planner → circle → prayers → analytics data', () async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-journey';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);

      // 1. Onboarding preferences
      await firestore.doc(FirestorePaths.userSettings(uid)).set(
        cairoSettings(
          calculationMethod: CalculationMethods.mwl,
          madhab: MadhabOptions.standard,
        ).toFirestore(),
      );
      final settings = await firestore.doc(FirestorePaths.userSettings(uid)).get();
      expect(settings.data()?['onboardingComplete'], isTrue);
      expect(settings.data()?['calculationMethod'], CalculationMethods.mwl);

      // 2. Prayer times calculated offline
      final prayers = PrayerCalculator.calculateFromSettings(
        UserSettings.fromFirestore(settings.data()),
      );
      expect(prayers.length, 5);
      expect(prayers.first.name, PrayerName.fajr);

      // 3. Saved locations
      await firestore.collection(FirestorePaths.savedLocations(uid)).doc('home').set(
        testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home).toMap(),
      );
      await firestore.collection(FirestorePaths.savedLocations(uid)).doc('uni').set(
        testSavedLocation(id: 'uni', name: 'University', kind: LocationKind.work).toMap(),
      );
      final places = await firestore.collection(FirestorePaths.savedLocations(uid)).get();
      expect(places.docs.length, 2);

      // 4. Planner tags on weekday
      final wednesday = DateTime(2026, 6, 24);
      final contexts = PlannerEngine.buildDailyContexts(
        prayers: [
          PrayerTimeModel(
            name: PrayerName.fajr,
            time: DateTime(wednesday.year, wednesday.month, wednesday.day, 5, 10),
          ),
          PrayerTimeModel(
            name: PrayerName.dhuhr,
            time: DateTime(wednesday.year, wednesday.month, wednesday.day, 12, 30),
          ),
          PrayerTimeModel(
            name: PrayerName.asr,
            time: DateTime(wednesday.year, wednesday.month, wednesday.day, 15, 45),
          ),
          PrayerTimeModel(
            name: PrayerName.maghrib,
            time: DateTime(wednesday.year, wednesday.month, wednesday.day, 18, 20),
          ),
          PrayerTimeModel(
            name: PrayerName.isha,
            time: DateTime(wednesday.year, wednesday.month, wednesday.day, 19, 50),
          ),
        ],
        blocks: [testRoutineBlock(title: 'University')],
        date: wednesday,
      );
      expect(
        contexts.firstWhere((c) => c.prayerName == 'Dhuhr').tag,
        PrayerTag.atLocation,
      );
      expect(
        contexts.firstWhere((c) => c.prayerName == 'Fajr').tag,
        PrayerTag.atHome,
      );

      // 5. Accountability circle
      final circleResult = await CircleActions(firestore, auth).createCircle('Family');
      expect(circleResult.isSuccess, isTrue);
      final circleId = circleResult.circleId!;

      // 6. Complete all 5 prayers
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
      for (final prayer in PrayerName.values) {
        await PrayerLogActions(firestore, auth).checkOff(prayer);
      }
      final logs = await firestore
          .collection(FirestorePaths.prayerLogEntries(uid, dateKey))
          .get();
      expect(logs.docs.where((d) => d.data()['checkedOff'] == true).length, 5);

      // 7. Dua board
      await DuaActions(firestore, auth).postRequest(
        circleId: circleId,
        message: 'Exams tomorrow',
        authorName: 'Journey User',
      );
      final duas = await firestore.collection(FirestorePaths.duaRequests(circleId)).get();
      expect(duas.docs.first.data()['message'], 'Exams tomorrow');

      // 8. Settings update (dark mode flag in prefs doc)
      await firestore.doc(FirestorePaths.userSettings(uid)).update({
        'themeMode': 'dark',
        'locale': 'ar',
      });
      final updatedSettings =
          await firestore.doc(FirestorePaths.userSettings(uid)).get();
      expect(updatedSettings.data()?['themeMode'], 'dark');
      expect(updatedSettings.data()?['locale'], 'ar');
    });
  });
}
