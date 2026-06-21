import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/providers/app_preferences_provider.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/settings/screens/settings_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SettingsScreen extended', () {
    testWidgets('shows prayer app and account sections', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Prayer calculation'), findsOneWidget);
      expect(find.text('Language'), findsWidgets);
      expect(find.text('Theme'), findsWidgets);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('arabic numerals toggle updates preferences', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      final switchFinder = find.byType(SwitchListTile).first;
      await tester.tap(switchFinder);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(appPreferencesProvider).arabicNumerals,
        isTrue,
      );
    });

    testWidgets('theme dropdown includes system light and dark', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<AppThemePreference>));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('shows notification prayer toggles', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Isha'), findsOneWidget);
    });

    testWidgets('ramadan dropdown offers auto on and off', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Ramadan mode'), findsWidgets);
      await tester.tap(find.byType(DropdownButton<RamadanPreference>));
      await tester.pumpAndSettle();

      expect(find.text('Auto-detect'), findsWidgets);
      expect(find.text('Always on'), findsWidgets);
      expect(find.text('Off'), findsWidgets);
    });

    testWidgets('sign out list tile is tappable', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(ListTile, 'Sign out'), findsOneWidget);
    });

    testWidgets('delete account dialog can be cancelled', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            userSettingsProvider.overrideWith(
              (ref) => Stream.value(cairoSettings()),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('permanently deletes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
