import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/commute/screens/commute_screen.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';

import '../helpers/test_helpers.dart';

Future<void> pumpCommuteScreen(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  setLargeScreen(tester);
  await tester.pumpWidget(
    buildTestApp(
      overrides: [
        noopHomeSeederOverride(),
        ...overrides,
      ],
      child: const CommuteScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('CommuteScreen', () {
    testWidgets('shows route from current location to home', (tester) async {
      await pumpCommuteScreen(
        tester,
        overrides: [
          savedLocationsOverride([
            testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
          ]),
        ],
      );

      expect(find.text('Smart Commute Advisor'), findsOneWidget);
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Can I Make It?'), findsOneWidget);
    });

    testWidgets('disables button when home is not set', (tester) async {
      await pumpCommuteScreen(
        tester,
        overrides: [
          userSettingsProvider.overrideWith(
            (ref) => Stream.value(const UserSettings()),
          ),
        ],
      );

      expect(find.textContaining('Set your home in My Places'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Can I Make It?'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows green verdict when commute succeeds', (tester) async {
      await pumpCommuteScreen(
        tester,
        overrides: [
          savedLocationsOverride([
            testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
          ]),
          commuteStateOverride(
            CommuteState(
              result: testCommuteResult(verdict: CommuteVerdict.green),
            ),
          ),
        ],
      );

      expect(find.text('Safe to go'), findsOneWidget);
    });

    testWidgets('shows red verdict message', (tester) async {
      await pumpCommuteScreen(
        tester,
        overrides: [
          savedLocationsOverride([
            testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
          ]),
          commuteStateOverride(
            CommuteState(
              result: testCommuteResult(
                verdict: CommuteVerdict.red,
                drivingMinutes: 45,
                minutesUntilPrayer: 30,
              ),
            ),
          ),
        ],
      );

      expect(find.text('Pray before you leave'), findsOneWidget);
      expect(find.text('Nearby mosques'), findsOneWidget);
    });

    testWidgets('shows ORS configuration error', (tester) async {
      await pumpCommuteScreen(
        tester,
        overrides: [
          savedLocationsOverride([
            testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
          ]),
          commuteStateOverride(
            const CommuteState(
              error:
                  'Routing is not configured. Add your free ORS_API_KEY to .env '
                  '(sign up at openrouteservice.org).',
            ),
          ),
        ],
      );

      expect(find.textContaining('ORS_API_KEY'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
