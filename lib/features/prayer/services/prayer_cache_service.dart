import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/user_settings.dart';
import '../models/hijri_date_info.dart';
import '../models/prayer_time_model.dart';

/// Persists locally calculated prayer times for instant cold-start display.
/// No network — reads/writes SharedPreferences only.
class PrayerCacheService {
  PrayerCacheService._();

  static final PrayerCacheService instance = PrayerCacheService._();

  static const _cacheKey = 'prayer_times_cache_v1';
  static const _lastSyncKey = 'aladhan_last_sync_date';
  static const _hijriDayKey = 'hijri_day';
  static const _hijriMonthNumKey = 'hijri_month_num';
  static const _hijriMonthEnKey = 'hijri_month_en';
  static const _hijriMonthArKey = 'hijri_month_ar';
  static const _hijriYearKey = 'hijri_year';

  Future<CachedPrayerDay?> load(String dateKey, UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['dateKey'] != dateKey) return null;

      final lat = (map['latitude'] as num?)?.toDouble();
      final lng = (map['longitude'] as num?)?.toDouble();
      if (lat == null ||
          lng == null ||
          settings.latitude == null ||
          settings.longitude == null) {
        return null;
      }

      final moved = _distanceMeters(lat, lng, settings.latitude!, settings.longitude!);
      if (moved > 500) return null;

      if (map['calculationMethod'] != settings.calculationMethod ||
          map['madhab'] != settings.madhab) {
        return null;
      }

      final prayersJson = map['prayers'] as List<dynamic>?;
      if (prayersJson == null) return null;

      final prayers = prayersJson
          .map((item) => PrayerTimeModel.fromFirestore(item as Map<String, dynamic>))
          .toList();

      if (prayers.length != 5) return null;
      return CachedPrayerDay(dateKey: dateKey, prayers: prayers);
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String dateKey,
    required List<PrayerTimeModel> prayers,
    required UserSettings settings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'dateKey': dateKey,
      'latitude': settings.latitude,
      'longitude': settings.longitude,
      'calculationMethod': settings.calculationMethod,
      'madhab': settings.madhab,
      'prayers': prayers.map((p) => p.toFirestore()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_cacheKey, payload);
  }

  Future<String?> lastSyncDateKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  Future<void> markSynced(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, dateKey);
  }

  Future<void> saveHijriDate(HijriDateInfo hijri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hijriDayKey, hijri.day);
    await prefs.setInt(_hijriMonthNumKey, hijri.monthNum);
    await prefs.setString(_hijriMonthEnKey, hijri.monthEn);
    await prefs.setString(_hijriMonthArKey, hijri.monthAr);
    await prefs.setInt(_hijriYearKey, hijri.year);
  }

  Future<HijriDateInfo?> loadHijriDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_hijriDayKey)) return null;

    return HijriDateInfo(
      day: prefs.getInt(_hijriDayKey) ?? 1,
      monthNum: prefs.getInt(_hijriMonthNumKey) ?? 1,
      monthEn: prefs.getString(_hijriMonthEnKey) ?? '',
      monthAr: prefs.getString(_hijriMonthArKey) ?? '',
      year: prefs.getInt(_hijriYearKey) ?? 1440,
    );
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
}

class CachedPrayerDay {
  const CachedPrayerDay({required this.dateKey, required this.prayers});

  final String dateKey;
  final List<PrayerTimeModel> prayers;
}
