import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/locations/services/open_route_service.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/providers/locations_provider.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

import '../helpers/test_helpers.dart';

class _StubOpenRouteService extends OpenRouteService {
  _StubOpenRouteService({required this.route});

  final RouteSummary? route;

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
      route;
}

void main() {
  group('Commute integration', () {
    testWidgets('calculate persists green verdict in provider state', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      const uid = 'uid-commute';
      final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
      final dhuhr = PrayerTimeModel(
        name: PrayerName.dhuhr,
        time: DateTime.now().add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
            openRouteServiceProvider.overrideWith(
              (ref) => _StubOpenRouteService(
                route: const RouteSummary(
                  distanceMeters: 5000,
                  durationSeconds: 20 * 60,
                ),
              ),
            ),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: cairoPrayers(),
                nextPrayer: dhuhr,
                isLoading: false,
              ),
            ),
            savedLocationsOverride([
              testSavedLocation(id: 'home', name: 'Home', kind: LocationKind.home),
            ]),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await ref.read(commuteProvider.notifier).calculate(
                            origin: const CommuteEndpoint(
                              label: 'Current',
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
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.text('Calculate')),
      );
      final state = container.read(commuteProvider);
      expect(state.result, isNotNull);
      expect(state.result!.verdict, CommuteVerdict.green);
      expect(state.error, isNull);
    });

    testWidgets('shows error when ORS is not configured', (tester) async {
      setLargeScreen(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openRouteServiceProvider.overrideWith((ref) => OpenRouteService()),
            prayerStateOverride(
              PrayerState(
                todaysPrayers: cairoPrayers(),
                nextPrayer: cairoPrayers().firstWhere((p) => p.name == PrayerName.dhuhr),
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
                              label: 'Current',
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
      await tester.pump(const Duration(milliseconds: 200));

      final container = ProviderScope.containerOf(
        tester.element(find.text('Calculate')),
      );
      final state = container.read(commuteProvider);
      expect(state.error, contains('ORS_API_KEY'));
    });
  });
}
