import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/services/home_widget_service.dart';

/// Runs before all tests — initializes Firebase mocks so Firestore/Auth don't crash.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();

  const homeWidgetChannel = MethodChannel('home_widget');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(homeWidgetChannel, (_) async => true);

  HomeWidgetService.testMode = true;

  await testMain();
}
