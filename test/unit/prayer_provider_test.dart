import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/prayer/services/aladhan_sync_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_cache_service.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

import '../helpers/test_helpers.dart';

class _CountingSyncService extends AlAdhanSyncService {
  int syncCallCount = 0;

  @override
  Future<void> syncIfNeeded(
    UserSettings settings, {
    required List<PrayerTimeModel> localPrayers,
    DateTime? syncDate,
    bool isHighLatitudeEstimate = false,
  }) async {
    syncCallCount++;
  }
}

void main() {
  group('PrayerNotifier', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late ProviderContainer container;
    late _CountingSyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-prayer'), signedIn: true);
      syncService = _CountingSyncService();
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
          prayerProvider.overrideWith(
            (ref) => PrayerNotifier(
              firestore,
              auth,
              ref,
              autoInit: false,
              syncService: syncService,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    PrayerNotifier readNotifier() => container.read(prayerProvider.notifier);

    test('calculatePrayers produces 5 prayers from cairoSettings', () async {
      await readNotifier().calculatePrayers(cairoSettings());

      final state = container.read(prayerProvider);
      expect(state.isLoading, isFalse);
      expect(state.todaysPrayers.length, 5);
      expect(
        state.todaysPrayers.map((p) => p.name).toSet(),
        PrayerName.values.toSet(),
      );
    });

    test('calculatePrayers loads from cache first', () async {
      final settings = cairoSettings();
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());
      final today = DateTime.now();
      final cachedPrayers = [
        PrayerTimeModel(
          name: PrayerName.fajr,
          time: DateTime(today.year, today.month, today.day, 4, 30),
        ),
        PrayerTimeModel(
          name: PrayerName.dhuhr,
          time: DateTime(today.year, today.month, today.day, 12, 15),
        ),
        PrayerTimeModel(
          name: PrayerName.asr,
          time: DateTime(today.year, today.month, today.day, 15, 45),
        ),
        PrayerTimeModel(
          name: PrayerName.maghrib,
          time: DateTime(today.year, today.month, today.day, 18, 10),
        ),
        PrayerTimeModel(
          name: PrayerName.isha,
          time: DateTime(today.year, today.month, today.day, 19, 40),
        ),
      ];

      await PrayerCacheService.instance.save(
        dateKey: dateKey,
        prayers: cachedPrayers,
        settings: settings,
      );

      await readNotifier().calculatePrayers(settings);

      final state = container.read(prayerProvider);
      expect(state.todaysPrayers.length, 5);
      final loaded = await PrayerCacheService.instance.load(dateKey, settings);
      expect(loaded, isNotNull);
      expect(loaded!.prayers.first.time.hour, cachedPrayers.first.time.hour);
    });

    test('calculatePrayers triggers syncIfNeeded via injectable service', () async {
      await readNotifier().calculatePrayers(cairoSettings());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncService.syncCallCount, 1);
    });

    test('refresh recalculates prayers with current settings', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          firebaseAuthProvider.overrideWithValue(auth),
          userSettingsProvider.overrideWith((ref) => Stream.value(cairoSettings())),
          prayerProvider.overrideWith(
            (ref) => PrayerNotifier(
              firestore,
              auth,
              ref,
              autoInit: false,
              syncService: syncService,
            ),
          ),
        ],
      );

      await container.read(userSettingsProvider.future);
      await readNotifier().calculatePrayers(cairoSettings());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await readNotifier().refresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(prayerProvider);
      expect(state.todaysPrayers.length, 5);
      expect(state.error, isNull);
      expect(syncService.syncCallCount, 2);
    });

    test('calculatePrayers persists prayer log under the user day path', () async {
      final settings = cairoSettings();
      final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());

      await readNotifier().calculatePrayers(settings);

      final logDoc = await firestore
          .doc(FirestorePaths.prayerLog('uid-prayer', dateKey))
          .get();

      expect(logDoc.exists, isTrue);
      expect(logDoc.data()?['date'], dateKey);
      expect(logDoc.data()?['latitude'], settings.latitude);
      expect(logDoc.data()?['longitude'], settings.longitude);
      expect((logDoc.data()?['prayers'] as List?)?.length, 5);
    });

    test('calculatePrayers sets location error when latitude or longitude is missing', () async {
      const settings = UserSettings(
        onboardingComplete: true,
        calculationMethod: CalculationMethods.mwl,
        madhab: MadhabOptions.standard,
      );

      await readNotifier().calculatePrayers(settings);

      final state = container.read(prayerProvider);
      expect(state.isLoading, isFalse);
      expect(state.todaysPrayers, isEmpty);
      expect(state.error, 'Location not configured.');
    });
  });

  group('prayer formatting helpers', () {
    test('formatDuration renders hours minutes and seconds', () {
      expect(
        formatDuration(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2h 03m 04s',
      );
      expect(formatDuration(const Duration(minutes: 5, seconds: 9)), '5m 09s');
      expect(formatDuration(Duration.zero), 'Now');
    });

    test('formatCountdownCompact renders hh:mm:ss style output', () {
      expect(
        formatCountdownCompact(const Duration(hours: 7, minutes: 4, seconds: 5)),
        '7:04:05',
      );
      expect(formatCountdownCompact(Duration.zero), 'Now');
    });
  });

  group('timeUntilNextPrayerProvider', () {
    test('emits a positive duration for the next prayer', () async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          prayerProvider.overrideWith(
            (ref) => PrayerNotifier(
              FakeFirebaseFirestore(),
              MockFirebaseAuth(),
              ref,
              initialState: PrayerState(
                todaysPrayers: const [],
                nextPrayer: PrayerTimeModel(
                  name: PrayerName.asr,
                  time: now.add(const Duration(seconds: 5)),
                ),
                isLoading: false,
              ),
              autoInit: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final duration = await container.read(timeUntilNextPrayerProvider.future);

      expect(duration, greaterThan(Duration.zero));
      expect(duration, lessThanOrEqualTo(const Duration(seconds: 5)));
    });
  });
}
