import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/widgets/commute_verdict_card.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CommuteVerdictCard', () {
    testWidgets('shows green safe message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: CommuteVerdictCard(
            result: testCommuteResult(
              verdict: CommuteVerdict.green,
              drivingMinutes: 20,
              minutesUntilPrayer: 50,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Safe to go'), findsOneWidget);
      expect(find.textContaining('Safe to go!'), findsOneWidget);
      expect(find.textContaining('20 min'), findsWidgets);
    });

    testWidgets('shows red pray-before-leave message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: CommuteVerdictCard(
            result: testCommuteResult(
              verdict: CommuteVerdict.red,
              drivingMinutes: 45,
              minutesUntilPrayer: 30,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pray before you leave'), findsOneWidget);
      expect(find.textContaining('Stop!'), findsOneWidget);
    });
  });
}
