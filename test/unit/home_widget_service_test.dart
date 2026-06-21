import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ummah_pulse/core/services/home_widget_service.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

import '../helpers/test_helpers.dart';

void main() {
  const homeWidgetChannel = MethodChannel('home_widget');

  group('HomeWidgetService', () {
    final channelCalls = <String>[];

    setUpAll(() async {
      await initializeDateFormatting('en');
    });

    setUp(() {
      channelCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(homeWidgetChannel, (call) async {
            channelCalls.add(call.method);
            return true;
          });
    });

    tearDown(() {
      HomeWidgetService.testMode = false;
      HomeWidgetService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(homeWidgetChannel, (_) async => true);
    });

    test('testMode prevents initialize from crashing', () async {
      HomeWidgetService.testMode = true;

      await expectLater(HomeWidgetService.initialize(), completes);
    });

    test('updateWidgetData returns early in testMode', () async {
      HomeWidgetService.testMode = true;
      final prayers = cairoPrayers();
      final nextPrayer = prayers.firstWhere((p) => p.name == PrayerName.dhuhr);

      await expectLater(
        HomeWidgetService.updateWidgetData(
          nextPrayer: nextPrayer,
          todaysPrayers: prayers,
          localeCode: 'en',
        ),
        completes,
      );
    });

    test('startPeriodicUpdates returns early in testMode', () async {
      HomeWidgetService.testMode = true;
      final prayers = cairoPrayers();

      await expectLater(
        HomeWidgetService.startPeriodicUpdates(
          nextPrayer: prayers.first,
          todaysPrayers: prayers,
          localeCode: 'en',
        ),
        completes,
      );
    });

    test('initialize completes when testMode is false', () async {
      HomeWidgetService.testMode = false;

      await expectLater(HomeWidgetService.initialize(), completes);
      expect(channelCalls, contains('setAppGroupId'));
      expect(channelCalls, contains('registerBackgroundCallback'));
    });

    test('updateWidgetData completes when channel is mocked', () async {
      HomeWidgetService.testMode = false;
      final prayers = cairoPrayers(date: DateTime.now().add(const Duration(days: 1)));
      final nextPrayer = prayers.firstWhere((p) => p.name == PrayerName.dhuhr);

      await expectLater(
        HomeWidgetService.updateWidgetData(
          nextPrayer: nextPrayer,
          todaysPrayers: prayers,
          localeCode: 'en',
        ),
        completes,
      );

      expect(channelCalls.where((method) => method == 'saveWidgetData').length, 4);
      expect(channelCalls, contains('updateWidget'));
    });

    test('dispose cancels the periodic update timer', () {
      HomeWidgetService.testMode = false;
      final prayers = cairoPrayers(date: DateTime.now().add(const Duration(days: 1)));

      fakeAsync((async) {
        unawaited(
          HomeWidgetService.startPeriodicUpdates(
            nextPrayer: prayers.first,
            todaysPrayers: prayers,
            localeCode: 'en',
          ),
        );
        async.flushMicrotasks();

        expect(channelCalls.where((method) => method == 'updateWidget').length, 1);

        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();
        expect(channelCalls.where((method) => method == 'updateWidget').length, 2);

        HomeWidgetService.dispose();

        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();
        expect(channelCalls.where((method) => method == 'updateWidget').length, 2);
      });
    });
  });
}
