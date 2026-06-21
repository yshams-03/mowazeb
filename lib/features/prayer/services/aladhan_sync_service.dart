import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_settings.dart';
import '../models/hijri_date_info.dart';
import '../models/prayer_time_model.dart';
import 'aladhan_service.dart';
import 'prayer_cache_service.dart';
import 'prayer_calculator.dart';

/// Runs at most once per calendar day when online — syncs AlAdhan data for
/// Hijri display and server-side verification. Never overrides local UI times.
class AlAdhanSyncService {
  AlAdhanSyncService({
    AlAdhanService? aladhan,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _aladhan = aladhan ?? AlAdhanService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final AlAdhanService _aladhan;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Once per day: fetch AlAdhan, store Hijri in SharedPreferences, log diffs.
  Future<void> syncIfNeeded(
    UserSettings settings, {
    required List<PrayerTimeModel> localPrayers,
    DateTime? syncDate,
    bool isHighLatitudeEstimate = false,
  }) async {
    if (!settings.isComplete) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateKey = PrayerCalculator.dateKeyFor(today);
    final lastSync = await PrayerCacheService.instance.lastSyncDateKey();
    if (lastSync == dateKey) return;

    final apiDate = syncDate ?? today;

    try {
      try {
        await _functions.httpsCallable('syncIslamicData').call();
      } catch (_) {
        // Callable may fail offline — continue with direct client fetch.
      }

      final result = await _aladhan.fetchTimings(
        latitude: settings.latitude!,
        longitude: settings.longitude!,
        calculationMethod: settings.calculationMethod!,
        madhab: settings.madhab!,
        date: apiDate,
      );

      if (result == null) {
        developer.log(
          'AlAdhan sync failed for $dateKey — will retry next launch',
          name: 'AlAdhanSync',
        );
        return;
      }

      AlAdhanService.logDiscrepancies(local: localPrayers, remote: result.prayers);

      if (result.hijri != null) {
        await PrayerCacheService.instance.saveHijriDate(result.hijri!);
      }

      await _firestore
          .doc('users/${user.uid}/islamic_data/$dateKey')
          .set(result.toFirestoreSync(), SetOptions(merge: true));

      final qibla = await _aladhan.fetchQiblaDirection(
        latitude: settings.latitude!,
        longitude: settings.longitude!,
      );
      if (qibla != null) {
        await _firestore.doc('users/$user.uid/islamic_data/qibla').set(
          {
            'direction': qibla,
            'latitude': settings.latitude,
            'longitude': settings.longitude,
            'source': 'aladhan',
            'updatedAt': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      }

      await PrayerCacheService.instance.markSynced(dateKey);

      if (isHighLatitudeEstimate) {
        developer.log(
          'AlAdhan sync used fallback date ${PrayerCalculator.dateKeyFor(apiDate)} '
          'for high-latitude consistency',
          name: 'AlAdhanSync',
        );
      }
    } catch (e, st) {
      developer.log(
        'AlAdhan sync error: $e',
        name: 'AlAdhanSync',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Hijri for UI: AlAdhan cache → hijri package fallback.
  static Future<HijriDateInfo> getHijriDate() async {
    final cached = await PrayerCacheService.instance.loadHijriDate();
    if (cached != null &&
        cached.monthEn.isNotEmpty &&
        cached.year > 1400 &&
        cached.day >= 1 &&
        cached.day <= 30) {
      return cached;
    }
    return HijriDateInfo.fromHijriPackage();
  }
}
