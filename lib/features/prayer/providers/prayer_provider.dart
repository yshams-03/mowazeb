import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/device_timezone.dart';
import '../../../core/models/user_settings.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/prayer_time_model.dart';
import '../services/aladhan_sync_service.dart';
import '../services/location_label_service.dart';
import '../services/prayer_cache_service.dart';
import '../services/prayer_calculator.dart';

class PrayerState {
  const PrayerState({
    this.todaysPrayers = const [],
    this.nextPrayer,
    this.isLoading = true,
    this.error,
    this.isHighLatitudeEstimate = false,
  });

  final List<PrayerTimeModel> todaysPrayers;
  final PrayerTimeModel? nextPrayer;
  final bool isLoading;
  final String? error;
  final bool isHighLatitudeEstimate;

  PrayerState copyWith({
    List<PrayerTimeModel>? todaysPrayers,
    PrayerTimeModel? nextPrayer,
    bool? isLoading,
    String? error,
    bool? isHighLatitudeEstimate,
    bool clearError = false,
  }) {
    return PrayerState(
      todaysPrayers: todaysPrayers ?? this.todaysPrayers,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isHighLatitudeEstimate:
          isHighLatitudeEstimate ?? this.isHighLatitudeEstimate,
    );
  }
}

final prayerProvider =
    StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  return PrayerNotifier(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref,
  );
});

final timeUntilNextPrayerProvider = StreamProvider<Duration>((ref) {
  final nextPrayerTimeMs = ref.watch(
    prayerProvider.select((state) => state.nextPrayer?.time.millisecondsSinceEpoch),
  );

  final target = nextPrayerTimeMs != null
      ? DateTime.fromMillisecondsSinceEpoch(nextPrayerTimeMs)
      : null;

  return _countdownStream(target);
});

Stream<Duration> _countdownStream(DateTime? target) async* {
  if (target == null) {
    yield Duration.zero;
    return;
  }

  while (true) {
    final diff = target.difference(DateTime.now());
    yield diff.isNegative ? Duration.zero : diff;
    await Future.delayed(const Duration(seconds: 1));
  }
}

class PrayerNotifier extends StateNotifier<PrayerState> {
  PrayerNotifier(
    this._firestore,
    this._auth,
    this._ref, {
    PrayerState? initialState,
    bool autoInit = true,
    AlAdhanSyncService? syncService,
  })  : _syncService = syncService ?? AlAdhanSyncService(),
        super(initialState ?? const PrayerState()) {
    if (autoInit && initialState == null) {
      _init();
    }
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref;
  Timer? _midnightTimer;
  Timer? _tickTimer;
  StreamSubscription<Position>? _locationSub;
  String? _lastCalculatedDate;
  List<PrayerTimeModel> _rawPrayers = [];
  final AlAdhanSyncService _syncService;

  static const _locationDistanceFilterMeters = 500;

  void _init() {
    _ref.listen<AsyncValue<UserSettings>>(userSettingsProvider, (_, next) {
      next.whenData((settings) {
        if (settings.isComplete) {
          calculatePrayers(settings);
          _startLocationWatch();
        }
      });
    });

    final settings = _ref.read(userSettingsProvider).valueOrNull;
    if (settings != null && settings.isComplete) {
      calculatePrayers(settings);
      _startLocationWatch();
    }

    _scheduleMidnightRecalculation();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _tickTimer?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  void _startLocationWatch() {
    if (_locationSub != null) return;

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: _locationDistanceFilterMeters,
      ),
    ).listen(_onLocationUpdate);
  }

  Future<void> _onLocationUpdate(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final settings = _ref.read(userSettingsProvider).valueOrNull;
    if (settings == null ||
        !settings.isComplete ||
        settings.latitude == null ||
        settings.longitude == null) {
      return;
    }

    final moved = Geolocator.distanceBetween(
      settings.latitude!,
      settings.longitude!,
      position.latitude,
      position.longitude,
    );
    if (moved < _locationDistanceFilterMeters) return;

    final label = await resolveLocationLabel(
      position.latitude,
      position.longitude,
    );

    await _firestore.doc(FirestorePaths.userSettings(user.uid)).set(
      {
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (label != null) 'locationLabel': label,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  void _scheduleMidnightRecalculation() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(durationUntilMidnight + const Duration(seconds: 1), () {
      final settings = _ref.read(userSettingsProvider).valueOrNull;
      if (settings != null && settings.isComplete) {
        calculatePrayers(settings);
      }
      _scheduleMidnightRecalculation();
    });
  }

  Future<void> calculatePrayers(UserSettings settings) async {
    if (settings.latitude == null || settings.longitude == null) {
      if (!state.isLoading && state.error == 'Location not configured.') return;
      state = state.copyWith(
        isLoading: false,
        error: 'Location not configured.',
      );
      return;
    }

    final dateKey = PrayerCalculator.dateKeyFor(DateTime.now());

    // Instant display from local cache — no network.
    final cached = await PrayerCacheService.instance.load(dateKey, settings);
    if (cached != null) {
      _applyCalculatedPrayers(cached.prayers, settings, showLoading: state.isLoading);
    } else if (state.todaysPrayers.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final calc = PrayerCalculator.calculateWithMetaFromSettings(settings);
      final rawPrayers = calc.prayers;
      _applyCalculatedPrayers(
        rawPrayers,
        settings,
        showLoading: false,
        isHighLatitudeEstimate: calc.isHighLatitudeEstimate,
      );

      await PrayerCacheService.instance.save(
        dateKey: dateKey,
        prayers: rawPrayers,
        settings: settings,
      );

      if (_lastCalculatedDate != dateKey) {
        _lastCalculatedDate = dateKey;
        await _persistPrayerLog(
          dateKey: dateKey,
          prayers: rawPrayers,
          settings: settings,
        );
      }

      unawaited(_syncService.syncIfNeeded(
        settings,
        localPrayers: rawPrayers,
        syncDate: calc.syncDate ?? DateTime.now(),
        isHighLatitudeEstimate: calc.isHighLatitudeEstimate,
      ));
      unawaited(_persistTimezoneIfNeeded(settings));
    } catch (e) {
      if (cached == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to calculate prayer times.',
        );
      }
    }
  }

  Future<void> _persistTimezoneIfNeeded(UserSettings settings) async {
    if (settings.timezone != null && settings.timezone!.isNotEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.doc(FirestorePaths.userSettings(user.uid)).set(
      DeviceTimezone.toFirestoreFields(),
      SetOptions(merge: true),
    );
  }

  void _applyCalculatedPrayers(
    List<PrayerTimeModel> rawPrayers,
    UserSettings settings, {
    required bool showLoading,
    bool isHighLatitudeEstimate = false,
  }) {
    final next = PrayerCalculator.detectNextPrayer(
      todayPrayers: rawPrayers,
      settings: settings,
      now: DateTime.now(),
    );

    _rawPrayers = rawPrayers;

    final annotated = PrayerCalculator.annotatePrayers(rawPrayers, DateTime.now());

    state = PrayerState(
      todaysPrayers: annotated,
      nextPrayer: next,
      isLoading: showLoading,
      isHighLatitudeEstimate: isHighLatitudeEstimate,
    );

    _startTickTimer();
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_rawPrayers.isEmpty) return;

      final settings = _ref.read(userSettingsProvider).valueOrNull;
      if (settings == null || !settings.isComplete) return;

      final now = DateTime.now();
      final annotated = PrayerCalculator.annotatePrayers(_rawPrayers, now);
      final next = PrayerCalculator.detectNextPrayer(
        todayPrayers: _rawPrayers,
        settings: settings,
        now: now,
      );

      state = state.copyWith(
        todaysPrayers: annotated,
        nextPrayer: next,
      );
    });
  }

  Future<void> _persistPrayerLog({
    required String dateKey,
    required List<PrayerTimeModel> prayers,
    required UserSettings settings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final log = PrayerDayLog(
      date: dateKey,
      prayers: prayers,
      latitude: settings.latitude!,
      longitude: settings.longitude!,
      calculationMethod: settings.calculationMethod!,
      madhab: settings.madhab!,
    );

    await _firestore
        .doc(FirestorePaths.prayerLog(user.uid, dateKey))
        .set(log.toFirestore(), SetOptions(merge: true));
  }

  Future<void> refresh() async {
    final settings = _ref.read(userSettingsProvider).valueOrNull;
    if (settings != null && settings.isComplete) {
      _lastCalculatedDate = null;
      await calculatePrayers(settings);
    }
  }
}

String formatDuration(Duration duration) {
  if (duration <= Duration.zero) {
    return 'Now';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Countdown like `07:40:15` (always hours:minutes:seconds to avoid
/// confusion with prayer clock times like `1:03 PM`).
String formatCountdownCompact(Duration duration) {
  if (duration <= Duration.zero) {
    return 'Now';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
