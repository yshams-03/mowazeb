import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/screens/analytics_screen.dart';
import 'package:ummah_pulse/features/analytics/widgets/streak_widget.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AnalyticsScreen', () {
    testWidgets('shows private lock banner and streak widget', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const AnalyticsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(
        find.textContaining('Private to you'),
        findsOneWidget,
      );
      expect(find.byType(StreakWidget), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
    });
  });
}
