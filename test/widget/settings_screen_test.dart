import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/settings/screens/settings_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('shows prayer and app settings sections', (tester) async {
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

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Calculation method'), findsOneWidget);
      expect(find.text('Madhab for Asr'), findsOneWidget);
      expect(find.text('Language'), findsWidgets);
      expect(find.text('Theme'), findsWidgets);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('delete account shows confirmation dialog', (tester) async {
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

      expect(
        find.textContaining('permanently deletes'),
        findsOneWidget,
      );
    });
  });
}
