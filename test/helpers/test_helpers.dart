import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/core/providers/router_provider.dart';
import 'package:ummah_pulse/core/theme/app_theme.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/l10n/app_localizations.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/providers/locations_provider.dart';
import 'package:ummah_pulse/features/locations/services/location_search_service.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';
import 'package:ummah_pulse/features/planner/models/routine_block.dart';
import 'package:ummah_pulse/features/planner/providers/planner_provider.dart';
import 'package:ummah_pulse/features/planner/services/planner_engine.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/community/models/accountability_circle.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/prayer/services/prayer_calculator.dart';

void setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

const testLatitude = PrayerCalculator.cairoLatitude;
const testLongitude = PrayerCalculator.cairoLongitude;

UserSettings cairoSettings({
  bool onboardingComplete = true,
  String calculationMethod = CalculationMethods.mwl,
  String madhab = MadhabOptions.standard,
}) {
  return UserSettings(
    onboardingComplete: onboardingComplete,
    calculationMethod: calculationMethod,
    madhab: madhab,
    latitude: testLatitude,
    longitude: testLongitude,
  );
}

List<PrayerTimeModel> cairoPrayers({DateTime? date}) {
  return PrayerCalculator.calculatePrayerTimes(
    latitude: testLatitude,
    longitude: testLongitude,
    calculationMethod: CalculationMethods.mwl,
    madhab: MadhabOptions.standard,
    date: date,
  );
}

Widget buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
  ThemeData? theme,
  Locale? locale,
}) {
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      ...overrides,
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Widget buildTestRouterApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    ),
  );
}

Widget buildTestGoRouterApp({
  required GoRouter router,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      ...overrides,
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

List<Override> authOverrides({
  User? user,
  UserSettings settings = const UserSettings(),
  bool authLoading = false,
  bool settingsLoading = false,
}) {
  return [
    authStateProvider.overrideWith(
      (ref) => authLoading ? const Stream.empty() : Stream.value(user),
    ),
    userSettingsProvider.overrideWith(
      (ref) => settingsLoading ? const Stream.empty() : Stream.value(settings),
    ),
  ];
}

Override prayerStateOverride(PrayerState state) {
  return prayerProvider.overrideWith(
    (ref) => PrayerNotifier(
      FakeFirebaseFirestore(),
      MockFirebaseAuth(),
      ref,
      initialState: state,
      autoInit: false,
    ),
  );
}

Override countdownOverride(Duration duration) {
  return timeUntilNextPrayerProvider.overrideWith(
    (ref) => Stream.value(duration),
  );
}

Override liveUserSettingsOverride(FakeFirebaseFirestore firestore) {
  return userSettingsProvider.overrideWith((ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Stream.value(const UserSettings());
    }

    return _userSettingsStream(firestore, user.uid);
  });
}

Stream<UserSettings> _userSettingsStream(
  FakeFirebaseFirestore firestore,
  String uid,
) {
  return Stream.multi((controller) async {
    controller.add(const UserSettings());

    final docRef = firestore.doc(FirestorePaths.userSettings(uid));
    final initial = await docRef.get();
    controller.add(UserSettings.fromFirestore(initial.data()));

    final subscription = docRef.snapshots().listen(
      (snapshot) =>
          controller.add(UserSettings.fromFirestore(snapshot.data())),
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
}

Override immediateUserSettingsOverride() {
  return userSettingsProvider.overrideWith((ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream.value(const UserSettings());
    }
    return Stream.value(const UserSettings(onboardingComplete: false));
  });
}

Stream<User?> testAuthStateChanges(MockFirebaseAuth auth) {
  return Stream.multi((controller) {
    controller.add(auth.currentUser);
    final subscription = auth.authStateChanges().listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
}

Override plannerStateOverride(PlannerState state) {
  return plannerProvider.overrideWith(
    (ref) => PlannerNotifier(
      FakeFirebaseFirestore(),
      MockFirebaseAuth(),
      ref,
      initialState: state,
      autoInit: false,
    ),
  );
}

Override savedLocationsOverride(List<SavedLocation> locations) {
  return savedLocationsProvider.overrideWith(
    (ref) => Stream.value(locations),
  );
}

Override locationSearchServiceOverride(LocationSearchService service) {
  return locationSearchServiceProvider.overrideWith((ref) => service);
}

Override noopHomeSeederOverride() {
  return homeLocationSeederProvider.overrideWith((ref) {});
}

SavedLocation testSavedLocation({
  String id = 'loc-1',
  String name = 'University',
  String address = 'AAST, Alexandria',
  LocationKind kind = LocationKind.other,
}) {
  return SavedLocation(
    id: id,
    name: name,
    address: address,
    latitude: 31.3069,
    longitude: 30.0606,
    kind: kind,
    updatedAt: DateTime(2026, 6, 21),
  );
}

RoutineBlock testRoutineBlock({
  String id = 'block-1',
  String title = 'University',
  String location = 'University',
  int startHour = 8,
  int endHour = 14,
  List<int> days = const [0, 1, 2, 3, 4],
}) {
  return RoutineBlock(
    id: id,
    title: title,
    location: location,
    startTime: TimeOfDay(hour: startHour, minute: 0),
    endTime: TimeOfDay(hour: endHour, minute: 0),
    daysOfWeek: days,
    color: const Color(0xFF0D9488),
  );
}

List<PrayerContext> testPrayerContexts({
  required DateTime date,
}) {
  final prayers = [
    PrayerTimeModel(name: PrayerName.fajr, time: DateTime(date.year, date.month, date.day, 5, 10)),
    PrayerTimeModel(name: PrayerName.dhuhr, time: DateTime(date.year, date.month, date.day, 12, 30)),
    PrayerTimeModel(name: PrayerName.asr, time: DateTime(date.year, date.month, date.day, 15, 45)),
    PrayerTimeModel(name: PrayerName.maghrib, time: DateTime(date.year, date.month, date.day, 18, 20)),
    PrayerTimeModel(name: PrayerName.isha, time: DateTime(date.year, date.month, date.day, 19, 50)),
  ];
  return PlannerEngine.buildDailyContexts(
    prayers: prayers,
    blocks: [testRoutineBlock()],
    date: date,
  );
}

Override commuteStateOverride(CommuteState state) {
  return commuteProvider.overrideWith(
    (ref) => CommuteNotifier(ref, initialState: state),
  );
}

CommuteResult testCommuteResult({
  CommuteVerdict verdict = CommuteVerdict.green,
  int drivingMinutes = 25,
  int minutesUntilPrayer = 60,
  List<MosqueResult> mosques = const [],
}) {
  final now = DateTime(2026, 6, 21, 11, 30);
  return CommuteResult(
    estimatedArrival: now.add(Duration(minutes: drivingMinutes)),
    drivingDurationMinutes: drivingMinutes,
    minutesUntilPrayer: minutesUntilPrayer,
    nextPrayerName: 'Dhuhr',
    nextPrayerTime: now.add(Duration(minutes: minutesUntilPrayer)),
    minutesBuffer: minutesUntilPrayer - drivingMinutes,
    verdict: verdict,
    nearbyMosques: mosques,
  );
}

Override userCirclesOverride(List<AccountabilityCircle> circles) {
  return userCirclesProvider.overrideWith((ref) => Stream.value(circles));
}

Override todayPrayerLogsOverride(TodayPrayerLogs logs) {
  return todayPrayerLogsProvider.overrideWith((ref) => Stream.value(logs));
}

AccountabilityCircle testCircle({
  String id = 'circle-1',
  String name = 'Family',
  String createdBy = 'uid-1',
  List<String> members = const ['uid-1'],
  String inviteCode = 'ABC123',
  int groupStreak = 3,
}) {
  return AccountabilityCircle(
    id: id,
    name: name,
    createdBy: createdBy,
    members: members,
    inviteCode: inviteCode,
    groupStreak: groupStreak,
  );
}

MemberPrayerFeed testMemberFeed({
  String uid = 'uid-1',
  String displayName = 'Yassin',
  bool isCurrentUser = true,
  Map<PrayerName, PrayerLogEntry>? entries,
}) {
  final defaultEntries = {
    for (final prayer in PrayerName.values)
      prayer: PrayerLogEntry(prayerName: prayer),
  };
  return MemberPrayerFeed(
    uid: uid,
    displayName: displayName,
    entries: entries ?? defaultEntries,
    isCurrentUser: isCurrentUser,
  );
}
