import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/core/providers/app_preferences_provider.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';

Future<ProviderContainer> _prefsContainer({
  FakeFirebaseFirestore? firestore,
  MockFirebaseAuth? auth,
  UserSettings? settings,
}) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(
    overrides: [
      firestoreProvider.overrideWithValue(firestore ?? FakeFirebaseFirestore()),
      firebaseAuthProvider.overrideWithValue(
        auth ?? MockFirebaseAuth(mockUser: MockUser(uid: 'uid-pref'), signedIn: true),
      ),
      if (settings != null)
        userSettingsProvider.overrideWith((ref) => Stream.value(settings)),
    ],
  );
  await container.read(sharedPreferencesProvider.future);
  return container;
}

void main() {
  group('AppPreferences', () {
    test('themeFromString maps known and default values', () {
      expect(AppPreferences.themeFromString('light'), AppThemePreference.light);
      expect(AppPreferences.themeFromString('dark'), AppThemePreference.dark);
      expect(AppPreferences.themeFromString('unknown'), AppThemePreference.system);
      expect(AppPreferences.themeFromString(null), AppThemePreference.system);
    });

    test('ramadanFromString maps known and default values', () {
      expect(AppPreferences.ramadanFromString('on'), RamadanPreference.on);
      expect(AppPreferences.ramadanFromString('off'), RamadanPreference.off);
      expect(AppPreferences.ramadanFromString(null), RamadanPreference.auto);
    });

    test('copyWith preserves unchanged fields', () {
      const prefs = AppPreferences(localeCode: 'en', arabicNumerals: false);
      final updated = prefs.copyWith(localeCode: 'ar', arabicNumerals: true);

      expect(updated.localeCode, 'ar');
      expect(updated.arabicNumerals, isTrue);
      expect(updated.theme, AppThemePreference.system);
    });
  });

  group('AppPreferencesController', () {
    test('setTheme persists and syncs to Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final container = await _prefsContainer(firestore: firestore);
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.notifier).setTheme(AppThemePreference.dark);

      expect(container.read(appPreferencesProvider).theme, AppThemePreference.dark);

      final doc = await firestore.doc(FirestorePaths.userSettings('uid-pref')).get();
      expect(doc.data()?['themeMode'], 'dark');
    });

    test('setLocale updates locale preference', () async {
      final container = await _prefsContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.notifier).setLocale('ar');

      expect(container.read(appPreferencesProvider).localeCode, 'ar');
    });

    test('setRamadan updates ramadan preference', () async {
      final container = await _prefsContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.notifier).setRamadan(RamadanPreference.on);

      expect(container.read(appPreferencesProvider).ramadan, RamadanPreference.on);
    });

    test('setArabicNumerals persists preference', () async {
      final container = await _prefsContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.notifier).setArabicNumerals(true);

      expect(container.read(appPreferencesProvider).arabicNumerals, isTrue);
    });

    test('loads saved preferences from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'pref_theme': 'dark',
        'pref_locale': 'ar',
        'pref_arabic_numerals': true,
        'pref_ramadan': 'on',
      });
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(mockUser: MockUser(uid: 'uid-pref'), signedIn: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);

      final prefs = container.read(appPreferencesProvider);
      expect(prefs.theme, AppThemePreference.dark);
      expect(prefs.localeCode, 'ar');
      expect(prefs.arabicNumerals, isTrue);
      expect(prefs.ramadan, RamadanPreference.on);
    });
  });
}
