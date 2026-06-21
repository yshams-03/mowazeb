import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/providers/locations_provider.dart';
import 'package:ummah_pulse/features/locations/services/open_route_service.dart';
import 'package:ummah_pulse/features/planner/models/prayer_context.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

import '../helpers/test_helpers.dart';

class _StubOpenRouteService extends OpenRouteService {
  @override
  bool get isConfigured => true;

  @override
  Future<RouteSummary?> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-car',
  }) async =>
      const RouteSummary(distanceMeters: 8000, durationSeconds: 20 * 60);
}

void main() {
  group('Planner to commute flow', () {
    test('home location + weekday block tags Dhuhr at University', () {
      final wednesday = DateTime(2026, 6, 24);
      final contexts = testPrayerContexts(date: wednesday);
      final dhuhr = contexts.firstWhere((c) => c.prayerName == 'Dhuhr');
      final fajr = contexts.firstWhere((c) => c.prayerName == 'Fajr');

      expect(dhuhr.tag, PrayerTag.atLocation);
      expect(dhuhr.blockTitle, 'University');
      expect(fajr.tag, PrayerTag.atHome);
    });

    testWidgets('home destination with mocked route yields GREEN verdict', (tester) async {
      setLargeScreen(tester);
      final dhuhr = PrayerTimeModel(
        name: PrayerName.dhuhr,
        time: DateTime.now().add(const Duration(minutes: 45)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openRouteServiceProvider.overrideWith((ref) => _StubOpenRouteService()),
            savedLocationsOverride([
              testSavedLocation(id: 'home-1', name: 'Home', kind: LocationKind.home),
            ]),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: cairoPrayers(),
                nextPrayer: dhuhr,
                isLoading: false,
              ),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await ref.read(commuteProvider.notifier).calculate(
                            origin: const CommuteEndpoint(
                              label: 'Current location',
                              latitude: 30.05,
                              longitude: 31.24,
                            ),
                            destination: const CommuteEndpoint(
                              label: 'Home',
                              latitude: 30.06,
                              longitude: 31.25,
                            ),
                          );
                    },
                    child: const Text('Calculate'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Calculate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final container = ProviderScope.containerOf(
        tester.element(find.text('Calculate')),
      );
      final state = container.read(commuteProvider);
      expect(state.result?.verdict, CommuteVerdict.green);
    });
  });
}
