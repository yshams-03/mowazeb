import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/services/stream_utils.dart';

void main() {
  group('combineLatestList', () {
    test('returns empty list for no streams', () async {
      final values = await combineLatestList<int>([]).first;
      expect(values, isEmpty);
    });

    test('wraps single stream in a list', () async {
      final controller = StreamController<int>();
      final future = combineLatestList<int>([controller.stream]).first;

      controller.add(42);
      final values = await future;
      expect(values, [42]);
      await controller.close();
    });

    test('emits when all streams have values', () async {
      final a = StreamController<int>();
      final b = StreamController<int>();
      final results = <List<int>>[];

      final subscription = combineLatestList<int>([a.stream, b.stream]).listen(results.add);

      a.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(results, isEmpty);

      b.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(results, [
        [1, 2],
      ]);

      a.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(results.last, [3, 2]);

      await subscription.cancel();
      await a.close();
      await b.close();
    });
  });
}
