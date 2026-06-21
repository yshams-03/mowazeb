import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/planner/models/prayer_context.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _wuduChannelId = 'wudu_nudge';
  static const _wuduChannelName = 'Wudu Reminders';
  static const _wuduBaseId = 2000;

  static bool _tzInitialized = false;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _wuduChannelId,
            _wuduChannelName,
            description: 'Reminders to make Wudu before transition prayers',
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    if (!_initialized) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> cancelWuduNudges() async {
    if (!_initialized) return;
    for (var i = 0; i < 10; i++) {
      await _plugin.cancel(_wuduBaseId + i);
    }
  }

  static Future<void> scheduleWuduNudges(List<PrayerContext> contexts) async {
    if (!_initialized) return;
    await cancelWuduNudges();

    var notificationIndex = 0;
    for (final context in contexts) {
      if (context.tag != PrayerTag.transition ||
          context.wuduNudgeTime == null) {
        continue;
      }

      final scheduled = context.wuduNudgeTime!;
      if (scheduled.isBefore(DateTime.now())) continue;

      final blockTitle = context.blockTitle ?? 'your activity';
      final body = context.wuduNotificationBody(blockTitle);
      if (body == null) continue;

      await _plugin.zonedSchedule(
        _wuduBaseId + notificationIndex,
        'Wudu reminder — ${context.prayerName}',
        body,
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _wuduChannelId,
            _wuduChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      notificationIndex++;
      if (notificationIndex >= 10) break;
    }
  }
}
