import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/planner/providers/ramadan_provider.dart';

void main() {
  group('RamadanState', () {
    test('isFastingHours is true between suhoor and iftar', () {
      final suhoor = DateTime(2026, 3, 10, 4, 40);
      final iftar = DateTime(2026, 3, 10, 18, 30);
      final state = RamadanState(
        isActive: true,
        suhoorTime: suhoor,
        iftarTime: iftar,
      );

      expect(state.isFastingHours(DateTime(2026, 3, 10, 12)), isTrue);
      expect(state.isFastingHours(DateTime(2026, 3, 10, 19)), isFalse);
    });

    test('iftarCountdown returns remaining duration before maghrib', () {
      final iftar = DateTime(2026, 3, 10, 18, 30);
      final state = RamadanState(isActive: true, iftarTime: iftar);
      final remaining = state.iftarCountdown(DateTime(2026, 3, 10, 17, 30));
      expect(remaining, const Duration(hours: 1));
    });
  });
}
