import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/planner/providers/planner_provider.dart';
import 'package:ummah_pulse/features/planner/screens/planner_screen.dart';
import 'package:ummah_pulse/features/planner/services/planner_engine.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PlannerScreen', () {
    testWidgets('testPlannerScreenLoads', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [
                  testRoutineBlock(title: 'University'),
                  testRoutineBlock(id: '2', title: 'Gym', startHour: 16, endHour: 17),
                ],
                todayContexts: testPrayerContexts(date: DateTime(2026, 6, 24)),
                isLoading: false,
              ),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Smart Day Planner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('testBlockAppearsOnCalendar', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [testRoutineBlock(title: 'University')],
                todayContexts: const [],
                isLoading: false,
              ),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('University'), findsWidgets);
    });

    testWidgets('testTodayPrayerPlanShows', (tester) async {
      setLargeScreen(tester);
      final contexts = testPrayerContexts(date: DateTime(2026, 6, 24));
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [testRoutineBlock()],
                todayContexts: contexts,
                isLoading: false,
              ),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(find.text("Today's Prayer Plan"), findsOneWidget);
      expect(find.text('Dhuhr'), findsWidgets);
    });

    testWidgets('testEmptyStateWhenNoBlocksToday', (tester) async {
      setLargeScreen(tester);
      final todayIndex = weekdayIndex(DateTime.now());
      final daysWithoutToday = List.generate(7, (i) => i).where((i) => i != todayIndex).toList();

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [
                  testRoutineBlock(days: daysWithoutToday),
                ],
                todayContexts: const [],
                isLoading: false,
              ),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('None of your blocks run on'), findsOneWidget);
    });

    testWidgets('testAddBlockButtonExists', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              const PlannerState(blocks: [], todayContexts: [], isLoading: false),
            ),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(FloatingActionButton, 'Add Block'), findsOneWidget);
    });

    testWidgets('testTapBlockOpensEditSheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            plannerStateOverride(
              PlannerState(
                blocks: [testRoutineBlock(title: 'University')],
                todayContexts: const [],
                isLoading: false,
              ),
            ),
            savedLocationsOverride([
              testSavedLocation(id: 'loc-1', name: 'University'),
            ]),
          ],
          child: const PlannerScreen(),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('University').at(0));
      await tester.pumpAndSettle();

      expect(find.text('Edit Routine Block'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
