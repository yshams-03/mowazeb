import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/hijri_date_info.dart';
import '../models/prayer_time_model.dart';
import 'aladhan_constants.dart';
import 'prayer_calculator.dart';

/// Cloud backup API client — fetches verified Islamic data for sync only.
/// Prayer times shown in the UI always come from [PrayerCalculator] (offline).
class AlAdhanService {
  AlAdhanService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AlAdhanTimingsResult?> fetchTimings({
    required double latitude,
    required double longitude,
    required String calculationMethod,
    required String madhab,
    DateTime? date,
  }) async {
    final target = date ?? DateTime.now();
    final dateKey = PrayerCalculator.dateKeyFor(target);
    final timestamp = AlAdhanConstants.unixTimestampForDate(target);
    final methodId = AlAdhanConstants.methodIdFor(calculationMethod);
    final school = AlAdhanConstants.schoolFor(madhab);

    final uri = Uri.parse(
      '${AlAdhanConstants.baseUrl}/timings/$timestamp'
      '?latitude=$latitude&longitude=$longitude'
      '&method=$methodId&school=$school',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 200) return null;

      final data = json['data'] as Map<String, dynamic>?;
      final timings = data?['timings'] as Map<String, dynamic>?;
      if (timings == null) return null;

      final meta = data?['meta'] as Map<String, dynamic>?;
      final timezone = meta?['timezone'] as String? ?? 'UTC';
      final hijriJson = data?['date']?['hijri'] as Map<String, dynamic>?;
      final hijri = hijriJson != null ? HijriDateInfo.fromAlAdhanJson(hijriJson) : null;

      final prayers = _parsePrayers(dateKey, timings);
      if (prayers.length != 5) return null;

      return AlAdhanTimingsResult(
        dateKey: dateKey,
        prayers: prayers,
        timezone: timezone,
        hijri: hijri,
      );
    } catch (_) {
      return null;
    }
  }

  /// Logs minute-level differences between local adhan and AlAdhan (debug only).
  static void logDiscrepancies({
    required List<PrayerTimeModel> local,
    required List<PrayerTimeModel> remote,
  }) {
    for (final localPrayer in local) {
      PrayerTimeModel? remotePrayer;
      for (final p in remote) {
        if (p.name == localPrayer.name) {
          remotePrayer = p;
          break;
        }
      }
      if (remotePrayer == null) continue;

      final diffMinutes = localPrayer.time.difference(remotePrayer.time).inMinutes.abs();
      if (diffMinutes > 2) {
        developer.log(
          'AlAdhan sync: ${localPrayer.name.displayName} differs by $diffMinutes min '
          '(local ${TimeOfDay.fromDateTime(localPrayer.time).format24()} vs '
          'API ${TimeOfDay.fromDateTime(remotePrayer.time).format24()})',
          name: 'AlAdhanSync',
        );
      }
    }
  }

  Future<double?> fetchQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${AlAdhanConstants.baseUrl}/qibla/$latitude/$longitude',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 200) return null;

      final direction = json['data']?['direction'];
      if (direction is num) return direction.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }

  List<PrayerTimeModel> _parsePrayers(
    String dateKey,
    Map<String, dynamic> timings,
  ) {
    const mapping = {
      'Fajr': PrayerName.fajr,
      'Dhuhr': PrayerName.dhuhr,
      'Asr': PrayerName.asr,
      'Maghrib': PrayerName.maghrib,
      'Isha': PrayerName.isha,
    };

    final result = <PrayerTimeModel>[];
    for (final entry in mapping.entries) {
      final raw = timings[entry.key];
      if (raw is! String) continue;
      final time = _localTimeToDateTime(dateKey, raw);
      result.add(PrayerTimeModel(name: entry.value, time: time));
    }
    return result;
  }

  DateTime _localTimeToDateTime(String dateKey, String timeStr) {
    final parts = dateKey.split('-').map(int.parse).toList();
    final clean = timeStr.split(' ').first;
    final timeParts = clean.split(':').map(int.parse).toList();

    return DateTime(
      parts[0],
      parts[1],
      parts[2],
      timeParts[0],
      timeParts[1],
    );
  }
}

extension on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class AlAdhanTimingsResult {
  const AlAdhanTimingsResult({
    required this.dateKey,
    required this.prayers,
    required this.timezone,
    this.hijri,
  });

  final String dateKey;
  final List<PrayerTimeModel> prayers;
  final String timezone;
  final HijriDateInfo? hijri;

  Map<String, dynamic> toFirestoreSync() {
    return {
      'dateKey': dateKey,
      'timezone': timezone,
      if (hijri != null) 'hijriDate': '${hijri!.day}-${hijri!.monthNum}-${hijri!.year}',
      if (hijri != null) ...hijri!.toPrefs(),
      'prayers': prayers.map((p) => p.toFirestore()).toList(),
      'source': 'aladhan',
      'syncedAt': DateTime.now().toIso8601String(),
    };
  }
}
