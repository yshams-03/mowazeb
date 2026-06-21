import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

void main() {
  group('PrayerLogEntry', () {
    test('completed factory sets checkedOff and status', () {
      final entry = PrayerLogEntry.completed(PrayerName.fajr);
      expect(entry.checkedOff, isTrue);
      expect(entry.status, PrayerLogStatus.completed);
      expect(entry.checkedAt, isNotNull);
    });

    test('fromFirestore parses status', () {
      final entry = PrayerLogEntry.fromFirestore(PrayerName.maghrib, {
        'checkedOff': false,
        'status': 'missed',
      });
      expect(entry.status, PrayerLogStatus.missed);
      expect(entry.checkedOff, isFalse);
    });
  });
}
