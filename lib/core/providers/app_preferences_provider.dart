import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/user_settings.dart';
import '../../features/auth/providers/auth_provider.dart';

enum AppThemePreference { system, light, dark }

enum RamadanPreference { auto, on, off }

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    this.localeCode = 'en',
    this.arabicNumerals = false,
    this.ramadan = RamadanPreference.auto,
  });

  final AppThemePreference theme;
  final String localeCode;
  final bool arabicNumerals;
  final RamadanPreference ramadan;

  ThemeMode get themeMode => switch (theme) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      };

  Locale get locale => Locale(localeCode);

  AppPreferences copyWith({
    AppThemePreference? theme,
    String? localeCode,
    bool? arabicNumerals,
    RamadanPreference? ramadan,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      localeCode: localeCode ?? this.localeCode,
      arabicNumerals: arabicNumerals ?? this.arabicNumerals,
      ramadan: ramadan ?? this.ramadan,
    );
  }

  static AppThemePreference themeFromString(String? raw) {
    return switch (raw) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }

  static RamadanPreference ramadanFromString(String? raw) {
    return switch (raw) {
      'on' => RamadanPreference.on,
      'off' => RamadanPreference.off,
      _ => RamadanPreference.auto,
    };
  }
}

class _PrefStore {
  _PrefStore(this._prefs);

  final SharedPreferences? _prefs;

  String? getString(String key) => _prefs?.getString(key);
  bool? getBool(String key) => _prefs?.getBool(key);

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
}

class AppPreferencesController extends StateNotifier<AppPreferences> {
  AppPreferencesController(this._store, this._ref)
      : super(const AppPreferences()) {
    _loadFromPrefs();
    _ref.listen<AsyncValue<UserSettings>>(userSettingsProvider, (_, next) {
      next.whenData(_mergeFromSettings);
    });
  }

  final _PrefStore _store;
  final Ref _ref;

  static const _themeKey = 'pref_theme';
  static const _localeKey = 'pref_locale';
  static const _numeralsKey = 'pref_arabic_numerals';
  static const _ramadanKey = 'pref_ramadan';

  void _loadFromPrefs() {
    state = AppPreferences(
      theme: AppPreferences.themeFromString(_store.getString(_themeKey)),
      localeCode: _store.getString(_localeKey) ?? 'en',
      arabicNumerals: _store.getBool(_numeralsKey) ?? false,
      ramadan: AppPreferences.ramadanFromString(_store.getString(_ramadanKey)),
    );
  }

  void _mergeFromSettings(UserSettings settings) {
    state = state.copyWith(
      theme: AppPreferences.themeFromString(settings.themeMode),
      localeCode: settings.locale ?? state.localeCode,
      arabicNumerals: settings.arabicNumerals ?? state.arabicNumerals,
      ramadan: AppPreferences.ramadanFromString(settings.ramadanModeOverride),
    );
  }

  Future<void> setTheme(AppThemePreference theme) async {
    state = state.copyWith(theme: theme);
    await _store.setString(_themeKey, theme.name);
    await _syncToFirestore({'themeMode': theme.name});
  }

  Future<void> setLocale(String localeCode) async {
    state = state.copyWith(localeCode: localeCode);
    await _store.setString(_localeKey, localeCode);
    await _syncToFirestore({'locale': localeCode});
  }

  Future<void> setArabicNumerals(bool enabled) async {
    state = state.copyWith(arabicNumerals: enabled);
    await _store.setBool(_numeralsKey, enabled);
    await _syncToFirestore({'arabicNumerals': enabled});
  }

  Future<void> setRamadan(RamadanPreference ramadan) async {
    state = state.copyWith(ramadan: ramadan);
    await _store.setString(_ramadanKey, ramadan.name);
    await _syncToFirestore({'ramadanModeOverride': ramadan.name});
  }

  Future<void> _syncToFirestore(Map<String, dynamic> data) async {
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await _ref.read(firestoreProvider).doc(FirestorePaths.userSettings(uid)).set(
          data,
          SetOptions(merge: true),
        );
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesController, AppPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return AppPreferencesController(_PrefStore(prefs), ref);
});
