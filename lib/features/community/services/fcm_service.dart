import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/router_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dua_provider.dart';

final pendingCircleIdProvider = StateProvider<String?>((ref) => null);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS; no UI work here.
}

class FcmService {
  FcmService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'circle_reminders';
  static const _channelName = 'Circle Reminders';

  static bool _initialized = false;
  static DuaActions? _duaActions;

  static Future<void> initialize({
    required WidgetRef ref,
    required GoRouter router,
  }) async {
    if (_initialized) return;

    _duaActions = ref.read(duaActionsProvider);

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'send_reminder') {
          _handleSendReminderAction(response.payload);
          return;
        }
        if (response.actionId == 'send_dua') {
          _handleSendDuaAction(response.payload);
          return;
        }
        _handleLocalNotificationTap(response.payload, ref, router);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );

    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(ref, token);
    }

    messaging.onTokenRefresh.listen((token) => _saveToken(ref, token));

    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteMessage(message, ref, router);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessage(initialMessage, ref, router);
    }

    _initialized = true;
  }

  static Future<void> _saveToken(WidgetRef ref, String token) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    await ref.read(firestoreProvider).doc(FirestorePaths.userFcmToken(uid)).set(
      {
        'token': token,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    final actions = type == 'missed_prayer'
        ? [
            const AndroidNotificationAction(
              'send_reminder',
              'Send Reminder',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'send_dua',
              'Send Dua',
              showsUserInterface: true,
            ),
          ]
        : null;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          actions: actions,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return [
      data['type'],
      data['circleId'],
      data['targetUid'],
      data['prayerName'],
      data['requestId'],
    ].join('|');
  }

  static Map<String, String?> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return const {};
    }
    if (payload.startsWith('circle:')) {
      return {'circleId': payload.substring('circle:'.length)};
    }
    final parts = payload.split('|');
    if (parts.length >= 5) {
      return {
        'type': parts[0],
        'circleId': parts[1],
        'targetUid': parts[2],
        'prayerName': parts[3],
        'requestId': parts[4],
      };
    }
    return {
      'circleId': parts.isNotEmpty ? parts[0] : null,
      'targetUid': parts.length > 1 ? parts[1] : null,
      'prayerName': parts.length > 2 ? parts[2] : null,
    };
  }

  static Future<void> _handleSendReminderAction(String? payload) async {
    final data = _decodePayload(payload);
    final targetUid = data['targetUid'];
    final prayerName = data['prayerName'];
    final circleId = data['circleId'];
    if (targetUid == null || prayerName == null || circleId == null) return;

    await sendPrayerReminder(
      targetUid: targetUid,
      prayerName: prayerName,
      circleId: circleId,
    );
  }

  static Future<void> _handleSendDuaAction(String? payload) async {
    final data = _decodePayload(payload);
    final targetUid = data['targetUid'];
    final prayerName = data['prayerName'];
    final circleId = data['circleId'];
    if (targetUid == null || prayerName == null || circleId == null) return;

    await _duaActions?.sendDuaForMissedPrayer(
      circleId: circleId,
      targetUid: targetUid,
      prayerName: prayerName,
    );
  }

  static void _handleRemoteMessage(
    RemoteMessage message,
    WidgetRef ref,
    GoRouter router,
  ) {
    final circleId = message.data['circleId'] as String?;
    if (circleId != null && circleId.isNotEmpty) {
      router.go('${RoutePaths.communityCircle}/$circleId');
      return;
    }

    ref.read(pendingCircleIdProvider.notifier).state = circleId;
  }

  static void _handleLocalNotificationTap(
    String? payload,
    WidgetRef ref,
    GoRouter router,
  ) {
    final data = _decodePayload(payload);
    final circleId = data['circleId'];
    if (circleId != null && circleId.isNotEmpty) {
      router.go('${RoutePaths.communityCircle}/$circleId');
      return;
    }

    ref.read(pendingCircleIdProvider.notifier).state = circleId;
  }

  static Future<void> sendPrayerReminder({
    required String targetUid,
    required String prayerName,
    required String circleId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('sendPrayerReminder');
    await callable.call<Map<String, dynamic>>({
      'targetUid': targetUid,
      'prayerName': prayerName,
      'circleId': circleId,
    });
  }
}

class CommunityMessagingBootstrap extends ConsumerStatefulWidget {
  const CommunityMessagingBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CommunityMessagingBootstrap> createState() =>
      _CommunityMessagingBootstrapState();
}

class _CommunityMessagingBootstrapState
    extends ConsumerState<CommunityMessagingBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final router = ref.read(routerProvider);
      await FcmService.initialize(ref: ref, router: router);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingCircleIdProvider, (_, circleId) {
      if (circleId != null && circleId.isNotEmpty) {
        ref.read(routerProvider).go('${RoutePaths.communityCircle}/$circleId');
        ref.read(pendingCircleIdProvider.notifier).state = null;
      }
    });

    return widget.child;
  }
}
