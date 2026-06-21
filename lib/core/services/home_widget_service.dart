import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../features/prayer/models/prayer_time_model.dart';

class HomeWidgetService {
  HomeWidgetService._();

  static const _androidName = 'PrayerWidgetProvider';
  static const _iosName = 'PrayerWidget';
  static Timer? _timer;

  /// When true, skips platform channel calls (used in widget tests).
  static bool testMode = false;

  static Future<void> initialize() async {
    if (testMode) return;
    await HomeWidget.setAppGroupId('group.com.ummahpulse.widget');
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  static Future<void> startPeriodicUpdates({
    required PrayerTimeModel? nextPrayer,
    required List<PrayerTimeModel> todaysPrayers,
    required String localeCode,
  }) async {
    if (testMode) return;

    await updateWidgetData(
      nextPrayer: nextPrayer,
      todaysPrayers: todaysPrayers,
      localeCode: localeCode,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      updateWidgetData(
        nextPrayer: nextPrayer,
        todaysPrayers: todaysPrayers,
        localeCode: localeCode,
      );
    });
  }

  static Future<void> updateWidgetData({
    required PrayerTimeModel? nextPrayer,
    required List<PrayerTimeModel> todaysPrayers,
    required String localeCode,
  }) async {
    if (testMode) return;

    final now = DateTime.now();
    final dateLabel = DateFormat.yMMMEd(localeCode).format(now);

    String countdown = '--:--';
    if (nextPrayer != null) {
      final diff = nextPrayer.time.difference(now);
      if (!diff.isNegative) {
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        countdown = '$h:${m.toString().padLeft(2, '0')}';
      } else {
        countdown = 'Now';
      }
    }

    await HomeWidget.saveWidgetData<String>('date', dateLabel);
    await HomeWidget.saveWidgetData<String>(
      'next_prayer',
      nextPrayer?.name.displayName ?? '—',
    );
    await HomeWidget.saveWidgetData<String>('countdown', countdown);

    final prayerLines = todaysPrayers
        .map((p) => '${p.name.displayName}|${DateFormat.jm().format(p.time)}')
        .join(';');
    await HomeWidget.saveWidgetData<String>('all_prayers', prayerLines);

    await HomeWidget.updateWidget(
      name: _androidName,
      iOSName: _iosName,
      androidName: _androidName,
    );
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.updateWidget(
    name: HomeWidgetService._androidName,
    iOSName: HomeWidgetService._iosName,
    androidName: HomeWidgetService._androidName,
  );
}
