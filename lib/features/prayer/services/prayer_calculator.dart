import 'package:adhan/adhan.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_settings.dart';
import '../models/prayer_time_model.dart';

/// Result of offline prayer calculation including high-latitude metadata.
class PrayerCalculationResult {
  const PrayerCalculationResult({
    required this.prayers,
    this.isHighLatitudeEstimate = false,
    this.syncDate,
  });

  final List<PrayerTimeModel> prayers;
  final bool isHighLatitudeEstimate;
  /// Date used for AlAdhan sync when high-latitude fallback applied.
  final DateTime? syncDate;
}

/// Pure prayer-time calculations — no network, no Firebase, no GPS.
///
/// Display times always come from the [adhan] package (instant, offline).
/// The AlAdhan REST API is used only for once-per-day background sync so
/// Cloud Functions can verify missed prayers independently of the device.
class PrayerCalculator {
  PrayerCalculator._();

  static const cairoLatitude = 30.0444;
  static const cairoLongitude = 31.2357;

  static List<PrayerTimeModel> calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required String calculationMethod,
    required String madhab,
    DateTime? date,
  }) {
    return calculateWithMeta(
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
      madhab: madhab,
      date: date,
    ).prayers;
  }

  static PrayerCalculationResult calculateWithMeta({
    required double latitude,
    required double longitude,
    required String calculationMethod,
    required String madhab,
    DateTime? date,
  }) {
    final targetDate = date ?? DateTime.now();
    final coordinates = Coordinates(latitude, longitude);
    final params = _buildCalculationParameters(
      calculationMethod,
      madhab,
      latitude: latitude,
    );
    final dateComponents = DateComponents.from(targetDate);
    final resolved = _resolvePrayerDateTimes(
      coordinates: coordinates,
      dateComponents: dateComponents,
      params: params,
      targetDate: targetDate,
    );

    final prayers = [
      PrayerTimeModel(name: PrayerName.fajr, time: resolved.times.fajr),
      PrayerTimeModel(name: PrayerName.dhuhr, time: resolved.times.dhuhr),
      PrayerTimeModel(name: PrayerName.asr, time: resolved.times.asr),
      PrayerTimeModel(name: PrayerName.maghrib, time: resolved.times.maghrib),
      PrayerTimeModel(name: PrayerName.isha, time: resolved.times.isha),
    ];

    return PrayerCalculationResult(
      prayers: prayers,
      isHighLatitudeEstimate: resolved.usedFallback,
      syncDate: resolved.fallbackSourceDate,
    );
  }

  static _ResolvedPrayerBundle _resolvePrayerDateTimes({
    required Coordinates coordinates,
    required DateComponents dateComponents,
    required CalculationParameters params,
    required DateTime targetDate,
  }) {
    try {
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
      return _ResolvedPrayerBundle(
        times: _ResolvedPrayerTimes(
          fajr: prayerTimes.fajr,
          dhuhr: prayerTimes.dhuhr,
          asr: prayerTimes.asr,
          maghrib: prayerTimes.maghrib,
          isha: prayerTimes.isha,
        ),
        usedFallback: false,
      );
    } on ArgumentError {
      for (var offset = 1; offset <= 7; offset++) {
        final neighbor = targetDate.subtract(Duration(days: offset));
        try {
          final neighborTimes = PrayerTimes(
            coordinates,
            DateComponents.from(neighbor),
            params,
          );
          return _ResolvedPrayerBundle(
            times: _ResolvedPrayerTimes(
              fajr: _onDate(neighborTimes.fajr, targetDate),
              dhuhr: _onDate(neighborTimes.dhuhr, targetDate),
              asr: _onDate(neighborTimes.asr, targetDate),
              maghrib: _onDate(neighborTimes.maghrib, targetDate),
              isha: _onDate(neighborTimes.isha, targetDate),
            ),
            usedFallback: true,
            fallbackSourceDate: neighbor,
          );
        } on ArgumentError {
          continue;
        }
      }
      rethrow;
    }
  }

  static DateTime _onDate(DateTime source, DateTime targetDate) {
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  static List<PrayerTimeModel> calculateFromSettings(
    UserSettings settings, {
    DateTime? date,
  }) {
    return calculateWithMetaFromSettings(settings, date: date).prayers;
  }

  static PrayerCalculationResult calculateWithMetaFromSettings(
    UserSettings settings, {
    DateTime? date,
  }) {
    return calculateWithMeta(
      latitude: settings.latitude!,
      longitude: settings.longitude!,
      calculationMethod: settings.calculationMethod ?? CalculationMethods.mwl,
      madhab: settings.madhab ?? MadhabOptions.standard,
      date: date,
    );
  }

  static List<PrayerTimeModel> annotatePrayers(
    List<PrayerTimeModel> prayers,
    DateTime now,
  ) {
    PrayerTimeModel? nextPrayer;
    Duration? smallestDiff;

    final annotated = prayers.map((prayer) {
      final isPassed = prayer.time.isBefore(now);
      if (!isPassed) {
        final diff = prayer.time.difference(now);
        if (smallestDiff == null || diff < smallestDiff!) {
          smallestDiff = diff;
          nextPrayer = prayer;
        }
      }
      return prayer.copyWith(isPassed: isPassed);
    }).toList();

    if (nextPrayer != null) {
      return annotated
          .map((p) => p.copyWith(isNext: p.name == nextPrayer!.name))
          .toList();
    }

    return annotated;
  }

  /// Returns the next upcoming prayer. When all of today's prayers have passed,
  /// returns tomorrow's Fajr.
  static PrayerTimeModel? detectNextPrayer({
    required List<PrayerTimeModel> todayPrayers,
    required UserSettings settings,
    required DateTime now,
  }) {
    final annotated = annotatePrayers(todayPrayers, now);
    for (final prayer in annotated) {
      if (prayer.isNext) return prayer;
    }

    if (annotated.isNotEmpty && annotated.every((p) => p.isPassed)) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowPrayers = calculateFromSettings(settings, date: tomorrow);
      return tomorrowPrayers.firstWhere((p) => p.name == PrayerName.fajr);
    }

    return null;
  }

  /// True when the calendar date changed and prayers should be recalculated.
  static bool shouldRecalculateForDate({
    required String? lastDateKey,
    required DateTime now,
  }) {
    final todayKey = _dateKey(now);
    return lastDateKey != todayKey;
  }

  static String dateKeyFor(DateTime date) => _dateKey(date);

  static CalculationMethod parseCalculationMethod(String? method) {
    switch (method) {
      case CalculationMethods.isna:
        return CalculationMethod.north_america;
      case CalculationMethods.egyptian:
        return CalculationMethod.egyptian;
      case CalculationMethods.ummAlQura:
        return CalculationMethod.umm_al_qura;
      case CalculationMethods.karachi:
        return CalculationMethod.karachi;
      case CalculationMethods.mwl:
        return CalculationMethod.muslim_world_league;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }

  static CalculationParameters _buildCalculationParameters(
    String calculationMethod,
    String madhab, {
    required double latitude,
  }) {
    final method = parseCalculationMethod(calculationMethod);
    final params = method.getParameters();
    params.madhab =
        madhab == MadhabOptions.hanafi ? Madhab.hanafi : Madhab.shafi;
    if (latitude.abs() > 48) {
      params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    }
    return params;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _ResolvedPrayerBundle {
  const _ResolvedPrayerBundle({
    required this.times,
    required this.usedFallback,
    this.fallbackSourceDate,
  });

  final _ResolvedPrayerTimes times;
  final bool usedFallback;
  final DateTime? fallbackSourceDate;
}

class _ResolvedPrayerTimes {
  const _ResolvedPrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
}
