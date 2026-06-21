import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/planner/providers/ramadan_provider.dart';

void main() {
  group('Ramadan mode flow', () {
    test('iftar countdown active during Ramadan state', () {
      final state = RamadanState(
        isActive: true,
        iftarTime: DateTime(2026, 3, 10, 18, 30),
        suhoorTime: DateTime(2026, 3, 10, 4, 40),
      );

      expect(state.iftarCountdown(DateTime(2026, 3, 10, 17, 0)), const Duration(hours: 1, minutes: 30));
    });

    test('fasting hours mute window between suhoor and iftar', () {
      final state = RamadanState(
        isActive: true,
        suhoorTime: DateTime(2026, 3, 10, 4, 40),
        iftarTime: DateTime(2026, 3, 10, 18, 30),
      );

      expect(state.isFastingHours(DateTime(2026, 3, 10, 12)), isTrue);
      expect(state.isFastingHours(DateTime(2026, 3, 10, 19)), isFalse);
    });
  });
}
