import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/commute/screens/commute_screen.dart';
import 'package:ummah_pulse/features/commute/widgets/commute_loading_shimmer.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CommuteScreen extended', () {
    testWidgets('shows loading shimmer while calculating', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            noopHomeSeederOverride(),
            savedLocationsOverride([
              testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
            ]),
            commuteStateOverride(const CommuteState(isLoading: true)),
          ],
          child: const CommuteScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CommuteLoadingShimmer), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('hides mosque section on green verdict', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            noopHomeSeederOverride(),
            savedLocationsOverride([
              testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
            ]),
            commuteStateOverride(
              CommuteState(result: testCommuteResult(verdict: CommuteVerdict.green)),
            ),
          ],
          child: const CommuteScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Safe to go'), findsOneWidget);
      expect(find.text('Nearby mosques'), findsNothing);
    });

    testWidgets('shows retry on network error', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            noopHomeSeederOverride(),
            savedLocationsOverride([
              testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
            ]),
            commuteStateOverride(
              const CommuteState(error: 'Something went wrong. Please try again.'),
            ),
          ],
          child: const CommuteScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('enabled button when home destination exists', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            noopHomeSeederOverride(),
            savedLocationsOverride([
              testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
            ]),
          ],
          child: const CommuteScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Can I Make It?'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('CommuteLoadingShimmer', () {
    testWidgets('renders placeholder bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommuteLoadingShimmer())),
      );

      expect(find.byType(CommuteLoadingShimmer), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
