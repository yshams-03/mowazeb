import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/utils/app_format.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

void main() {
  group('AppFormat', () {
    test('localizeDigits converts to eastern arabic numerals', () {
      expect(
        AppFormat.localizeDigits('123', arabicNumerals: true),
        '١٢٣',
      );
      expect(
        AppFormat.localizeDigits('123', arabicNumerals: false),
        '123',
      );
    });

    test('number converts digits when arabic numerals enabled', () {
      expect(AppFormat.number(42, arabicNumerals: true), '٤٢');
      expect(AppFormat.number(42, arabicNumerals: false), '42');
    });

    test('duration formats with arabic numerals', () {
      final result = AppFormat.duration(
        const Duration(minutes: 5, seconds: 7),
        arabicNumerals: true,
      );
      expect(result.contains('٥'), isTrue);
      expect(result.contains('٧'), isTrue);
    });

    test('duration returns Now for zero or negative duration', () {
      expect(
        AppFormat.duration(Duration.zero, arabicNumerals: true),
        'Now',
      );
      expect(
        AppFormat.duration(const Duration(seconds: -5), arabicNumerals: false),
        'Now',
      );
    });

    test('duration formats minutes and seconds without hours', () {
      expect(
        AppFormat.duration(
          const Duration(minutes: 12, seconds: 5),
          arabicNumerals: false,
        ),
        '12m 05s',
      );
    });

    test('duration formats seconds-only values', () {
      expect(
        AppFormat.duration(
          const Duration(seconds: 9),
          arabicNumerals: false,
        ),
        '9s',
      );
    });
  });

  group('formatCountdownCompact', () {
    test('formats hours minutes seconds with zero padding', () {
      expect(
        formatCountdownCompact(const Duration(hours: 1, minutes: 3, seconds: 5)),
        '1:03:05',
      );
    });

    test('returns Now for zero or negative duration', () {
      expect(formatCountdownCompact(Duration.zero), 'Now');
      expect(formatCountdownCompact(const Duration(seconds: -1)), 'Now');
    });

    test('formats under-one-hour countdowns with zero hours', () {
      expect(
        formatCountdownCompact(const Duration(minutes: 7, seconds: 4)),
        '0:07:04',
      );
    });
  });
}
