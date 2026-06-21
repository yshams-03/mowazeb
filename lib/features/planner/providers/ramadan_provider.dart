import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/providers/prayer_provider.dart';

class RamadanState {
  const RamadanState({
    this.isActive = false,
    this.isFirstDay = false,
    this.suhoorTime,
    this.iftarTime,
  });

  final bool isActive;
  final bool isFirstDay;
  final DateTime? suhoorTime;
  final DateTime? iftarTime;

  Duration? iftarCountdown(DateTime now) {
    if (!isActive || iftarTime == null) return null;
    if (now.isAfter(iftarTime!)) return null;
    return iftarTime!.difference(now);
  }

  bool isFastingHours(DateTime now) {
    if (!isActive || suhoorTime == null || iftarTime == null) return false;
    return !now.isBefore(suhoorTime!) && now.isBefore(iftarTime!);
  }
}

final ramadanProvider = Provider<RamadanState>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  final prayerState = ref.watch(prayerProvider);

  final hijri = HijriCalendar.fromDate(DateTime.now());
  final autoActive = hijri.hMonth == 9;

  final isActive = switch (prefs.ramadan) {
    RamadanPreference.on => true,
    RamadanPreference.off => false,
    RamadanPreference.auto => autoActive,
  };

  if (!isActive || prayerState.todaysPrayers.isEmpty) {
    return RamadanState(
      isActive: isActive,
      isFirstDay: isActive && hijri.hDay == 1,
    );
  }

  DateTime? fajr;
  DateTime? maghrib;
  for (final prayer in prayerState.todaysPrayers) {
    if (prayer.name == PrayerName.fajr) fajr = prayer.time;
    if (prayer.name == PrayerName.maghrib) maghrib = prayer.time;
  }

  final suhoor = fajr?.subtract(const Duration(minutes: 20));
  final iftar = maghrib;

  return RamadanState(
    isActive: isActive,
    isFirstDay: isActive && hijri.hDay == 1,
    suhoorTime: suhoor,
    iftarTime: iftar,
  );
});

/// Great-circle distance in km between two lat/lng points.
double distanceToMeccaKm(double lat, double lng) {
  const meccaLat = 21.4225;
  const meccaLng = 39.8262;
  const earthRadiusKm = 6371.0;

  final dLat = _toRad(meccaLat - lat);
  final dLng = _toRad(meccaLng - lng);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat)) *
          math.cos(_toRad(meccaLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRad(double deg) => deg * math.pi / 180;
