import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';

void main() {
  group('PrayerContext', () {
    test('displayTag for atHome', () {
      final context = PrayerContext(
        prayerName: 'Fajr',
        prayerTime: DateTime(2026, 6, 21, 5, 10),
        tag: PrayerTag.atHome,
      );

      expect(context.displayTag, '🏠 Pray at home');
    });

    test('displayTag for atLocation includes block title', () {
      final context = PrayerContext(
        prayerName: 'Dhuhr',
        prayerTime: DateTime(2026, 6, 21, 12, 30),
        tag: PrayerTag.atLocation,
        blockTitle: 'University',
        blockLocation: 'Campus',
      );

      expect(context.displayTag, '📍 Pray at Campus');
    });

    test('displayTag for transition', () {
      final context = PrayerContext(
        prayerName: 'Asr',
        prayerTime: DateTime(2026, 6, 21, 15, 45),
        tag: PrayerTag.transition,
      );

      expect(context.displayTag, '🔄 Transition — plan ahead');
    });

    test('wuduNotificationBody for transition prayer', () {
      final context = PrayerContext(
        prayerName: 'Dhuhr',
        prayerTime: DateTime(2026, 6, 21, 14, 15),
        tag: PrayerTag.transition,
        blockLocation: 'the library',
        wuduNudgeTime: DateTime(2026, 6, 21, 13, 55),
      );

      final body = context.wuduNotificationBody('University');
      expect(body, isNotNull);
      expect(body, contains('University'));
      expect(body, contains('the library'));
      expect(body, contains('Make Wudu now'));
    });

    test('wuduNotificationBody is null for non-transition', () {
      final context = PrayerContext(
        prayerName: 'Maghrib',
        prayerTime: DateTime(2026, 6, 21, 18, 20),
        tag: PrayerTag.atHome,
        wuduNudgeTime: DateTime(2026, 6, 21, 18, 0),
      );

      expect(context.wuduNotificationBody('Gym'), isNull);
    });
  });

  group('PrayerTag', () {
    test('emoji matches tag', () {
      expect(PrayerTag.atHome.emoji, '🏠');
      expect(PrayerTag.atLocation.emoji, '📍');
      expect(PrayerTag.transition.emoji, '🔄');
    });
  });
}
