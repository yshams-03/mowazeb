import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ummah_pulse/core/services/notification_service.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';

void main() {
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  Future<Object?> handleNotificationCalls(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
      case 'requestNotificationsPermission':
      case 'requestPermissions':
        return true;
      case 'createNotificationChannel':
      case 'cancel':
      case 'zonedSchedule':
        return null;
    }
    return null;
  }

  group('NotificationService', () {
    setUpAll(() {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            notificationsChannel,
            handleNotificationCalls,
          );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(notificationsChannel, null);
    });

    test('scheduleWuduNudges no-ops before initialize', () async {
      await expectLater(
        NotificationService.scheduleWuduNudges([
          PrayerContext(
            prayerName: 'Dhuhr',
            prayerTime: DateTime(2026, 6, 21, 12, 30),
            tag: PrayerTag.transition,
            blockTitle: 'University',
            wuduNudgeTime: DateTime(2026, 6, 21, 13, 45),
          ),
        ]),
        completes,
      );
    });

    test('cancelWuduNudges no-ops before initialize', () async {
      await expectLater(NotificationService.cancelWuduNudges(), completes);
    });

    test('requestPermissions no-ops before initialize', () async {
      await expectLater(NotificationService.requestPermissions(), completes);
    });

    test('initialize completes without crashing', () async {
      await expectLater(NotificationService.initialize(), completes);
    });

    test('requestPermissions completes after initialize', () async {
      await NotificationService.initialize();

      await expectLater(NotificationService.requestPermissions(), completes);
    });

    test('cancelWuduNudges completes after initialize', () async {
      await NotificationService.initialize();

      await expectLater(NotificationService.cancelWuduNudges(), completes);
    });

    test('scheduleWuduNudges completes with sample contexts', () async {
      await NotificationService.initialize();
      final now = DateTime.now();
      final contexts = [
        PrayerContext(
          prayerName: 'Dhuhr',
          prayerTime: now.add(const Duration(hours: 2)),
          tag: PrayerTag.transition,
          blockTitle: 'University',
          blockLocation: 'Campus mosque',
          wuduNudgeTime: now.add(const Duration(hours: 1, minutes: 30)),
        ),
        PrayerContext(
          prayerName: 'Asr',
          prayerTime: now.add(const Duration(hours: 5)),
          tag: PrayerTag.atLocation,
          blockTitle: 'Office',
        ),
        PrayerContext(
          prayerName: 'Maghrib',
          prayerTime: now.subtract(const Duration(minutes: 10)),
          tag: PrayerTag.transition,
          blockTitle: 'Gym',
          blockLocation: 'Neighborhood masjid',
          wuduNudgeTime: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      await expectLater(
        NotificationService.scheduleWuduNudges(contexts),
        completes,
      );
    });
  });
}
