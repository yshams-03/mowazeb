import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/models/user_settings.dart';
import 'package:ummah_pulse/features/commute/models/commute_result.dart';
import 'package:ummah_pulse/features/commute/providers/commute_provider.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/models/location_suggestion.dart';
import 'package:ummah_pulse/features/commute/services/mosque_search_service.dart';
import 'package:ummah_pulse/features/locations/providers/locations_provider.dart';
import 'package:ummah_pulse/features/locations/services/location_search_service.dart';
import 'package:ummah_pulse/features/locations/services/open_route_service.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';
import 'package:ummah_pulse/features/prayer/providers/prayer_provider.dart';

import '../helpers/test_helpers.dart';

class _StubOpenRouteService extends OpenRouteService {
  _StubOpenRouteService({this.route, this.onDirections});

  final RouteSummary? route;
  final Future<RouteSummary?> Function()? onDirections;

  @override
  bool get isConfigured => true;

  @override
  Future<RouteSummary?> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-car',
  }) async {
    if (onDirections != null) return onDirections!();
    return route;
  }
}

class _StubMosqueSearchService extends MosqueSearchService {
  _StubMosqueSearchService({this.mosques = const []});

  final List<MosqueResult> mosques;
  int callCount = 0;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<List<MosqueResult>> findNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    int limit = 3,
  }) async {
    callCount++;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return mosques;
  }
}

class _StubLocationSearchService extends LocationSearchService {
  _StubLocationSearchService({this.results = const []});

  final List<LocationSuggestion> results;
  String? lastQuery;
  double? lastBiasLat;
  double? lastBiasLng;

  @override
  Future<List<LocationSuggestion>> search(
    String query, {
    double? biasLat,
    double? biasLng,
    String? nearCity,
  }) async {
    lastQuery = query;
    lastBiasLat = biasLat;
    lastBiasLng = biasLng;
    return results;
  }
}

void main() {
  group('resolveHomeEndpointWith', () {
    test('prefers saved home location when available', () async {
      final endpoint = await resolveHomeEndpointWith(
        locations: [
          testSavedLocation(
            id: 'home-1',
            name: 'My Home',
            address: 'Alexandria, Egypt',
            kind: LocationKind.home,
          ),
        ],
        settings: cairoSettings(),
        searchService: _StubLocationSearchService(),
      );

      expect(endpoint, isNotNull);
      expect(endpoint!.label, 'My Home');
      expect(endpoint.latitude, 31.3069);
      expect(endpoint.longitude, 30.0606);
    });

    test('falls back to user settings coordinates before geocoding', () async {
      final endpoint = await resolveHomeEndpointWith(
        locations: const [],
        settings: cairoSettings().copyWith(
          homeAddress: '12 Garden Street',
          locationLabel: 'Cairo Home',
        ),
        searchService: _StubLocationSearchService(),
      );

      expect(endpoint, isNotNull);
      expect(endpoint!.label, '12 Garden Street');
      expect(endpoint.latitude, testLatitude);
      expect(endpoint.longitude, testLongitude);
    });

    test('geocodes homeAddress when saved home and coordinates are missing', () async {
      final searchService = _StubLocationSearchService(
        results: const [
          LocationSuggestion(
            displayName: 'Garden Street, Cairo, Egypt',
            shortName: 'Garden Street',
            address: 'Garden Street, Cairo, Egypt',
            latitude: 30.1,
            longitude: 31.3,
          ),
        ],
      );

      final endpoint = await resolveHomeEndpointWith(
        locations: const [],
        settings: const UserSettings(
          onboardingComplete: true,
          calculationMethod: 'MWL',
          madhab: 'Standard',
          homeAddress: ' Garden Street ',
        ),
        searchService: searchService,
      );

      expect(endpoint, isNotNull);
      expect(endpoint!.label, 'Garden Street');
      expect(endpoint.latitude, 30.1);
      expect(endpoint.longitude, 31.3);
      expect(searchService.lastQuery, 'Garden Street');
    });
  });
  group('CommuteNotifier', () {
    const origin = CommuteEndpoint(
      label: 'Current',
      latitude: 30.05,
      longitude: 31.24,
    );
    const destination = CommuteEndpoint(
      label: 'Home',
      latitude: 30.06,
      longitude: 31.25,
    );

    ProviderContainer buildContainer({
      required RouteSummary? route,
      PrayerTimeModel? nextPrayer,
      Future<RouteSummary?> Function()? onDirections,
      MosqueSearchService? mosqueSearchService,
      Override? prayerOverride,
    }) {
      final dhuhr = nextPrayer ??
          PrayerTimeModel(
            name: PrayerName.dhuhr,
            time: DateTime.now().add(const Duration(hours: 2)),
          );

      return ProviderContainer(
        overrides: [
          openRouteServiceProvider.overrideWith(
            (ref) => _StubOpenRouteService(route: route, onDirections: onDirections),
          ),
          mosqueSearchServiceProvider.overrideWith(
            (ref) => mosqueSearchService ?? _StubMosqueSearchService(),
          ),
          prayerOverride ??
              prayerStateOverride(
                PrayerState(
                  todaysPrayers: cairoPrayers(),
                  nextPrayer: dhuhr,
                  isLoading: false,
                ),
              ),
        ],
      );
    }

    test('GREEN verdict when buffer is sufficient', () async {
      final container = buildContainer(
        route: const RouteSummary(
          distanceMeters: 5000,
          durationSeconds: 20 * 60,
        ),
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.result, isNotNull);
      expect(state.result!.verdict, CommuteVerdict.green);
      expect(state.result!.minutesBuffer, greaterThanOrEqualTo(0));
    });

    test('RED verdict when buffer is insufficient', () async {
      final container = buildContainer(
        route: const RouteSummary(
          distanceMeters: 30000,
          durationSeconds: 120 * 60,
        ),
        nextPrayer: PrayerTimeModel(
          name: PrayerName.dhuhr,
          time: DateTime.now().add(const Duration(minutes: 30)),
        ),
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.result, isNotNull);
      expect(state.result!.verdict, CommuteVerdict.red);
      expect(state.result!.minutesBuffer, lessThan(0));
    });

    test('RED verdict triggers mosque search and includes nearby mosques', () async {
      final mosqueService = _StubMosqueSearchService(
        mosques: const [
          MosqueResult(
            name: 'Masjid Al Noor',
            address: 'Street 1',
            distanceMeters: 250,
            placeId: 'mosque-1',
            googleMapsUrl: 'https://maps.google.com/?q=mosque-1',
            latitude: 30.051,
            longitude: 31.241,
          ),
          MosqueResult(
            name: 'Masjid Ar Rahma',
            address: 'Street 2',
            distanceMeters: 400,
            placeId: 'mosque-2',
            googleMapsUrl: 'https://maps.google.com/?q=mosque-2',
            latitude: 30.052,
            longitude: 31.242,
          ),
          MosqueResult(
            name: 'Masjid Al Huda',
            address: 'Street 3',
            distanceMeters: 550,
            placeId: 'mosque-3',
            googleMapsUrl: 'https://maps.google.com/?q=mosque-3',
            latitude: 30.053,
            longitude: 31.243,
          ),
        ],
      );
      final container = buildContainer(
        route: const RouteSummary(
          distanceMeters: 30000,
          durationSeconds: 120 * 60,
        ),
        nextPrayer: PrayerTimeModel(
          name: PrayerName.dhuhr,
          time: DateTime.now().add(const Duration(minutes: 30)),
        ),
        mosqueSearchService: mosqueService,
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final result = container.read(commuteProvider).result;
      expect(result, isNotNull);
      expect(result!.verdict, CommuteVerdict.red);
      expect(mosqueService.callCount, 1);
      expect(mosqueService.lastLatitude, origin.latitude);
      expect(mosqueService.lastLongitude, origin.longitude);
      expect(result.nearbyMosques.map((m) => m.name), [
        'Masjid Al Noor',
        'Masjid Ar Rahma',
        'Masjid Al Huda',
      ]);
      expect(
        result.nearbyMosques.map((m) => m.googleMapsUrl),
        [
          'https://maps.google.com/?q=mosque-1',
          'https://maps.google.com/?q=mosque-2',
          'https://maps.google.com/?q=mosque-3',
        ],
      );
    });

    test('sets loading state during calculation', () async {
      final container = buildContainer(
        route: const RouteSummary(
          distanceMeters: 5000,
          durationSeconds: 20 * 60,
        ),
      );
      addTearDown(container.dispose);

      final future = container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      expect(container.read(commuteProvider).isLoading, isTrue);

      await future;

      expect(container.read(commuteProvider).isLoading, isFalse);
    });

    test('network error sets error message', () async {
      final container = buildContainer(
        route: null,
        onDirections: () async => throw const SocketException('offline'),
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, 'Something went wrong. Please try again.');
    });

    test('null route sets connection error message', () async {
      final container = buildContainer(route: null);
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(
        state.error,
        'Could not calculate route. Check your connection and retry.',
      );
    });

    test('null nextPrayer sets prayer loading error', () async {
      final container = buildContainer(
        route: const RouteSummary(
          distanceMeters: 5000,
          durationSeconds: 20 * 60,
        ),
        prayerOverride: prayerStateOverride(
          PrayerState(
            todaysPrayers: cairoPrayers(),
            isLoading: false,
          ),
        ),
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.result, isNull);
      expect(
        state.error,
        'Prayer times are not loaded yet. Pull to refresh and retry.',
      );
    });

    test('timeout error sets error message', () async {
      final container = buildContainer(
        route: null,
        onDirections: () async => throw TimeoutException('slow route'),
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      final state = container.read(commuteProvider);
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(state.error, 'Something went wrong. Please try again.');
    });

    test('ORS not configured sets configuration error', () async {
      final container = ProviderContainer(
        overrides: [
          openRouteServiceProvider.overrideWith((ref) => OpenRouteService()),
          prayerStateOverride(
            PrayerState(
              todaysPrayers: cairoPrayers(),
              nextPrayer: PrayerTimeModel(
                name: PrayerName.dhuhr,
                time: DateTime.now().add(const Duration(hours: 1)),
              ),
              isLoading: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(commuteProvider.notifier).calculate(
            origin: origin,
            destination: destination,
          );

      expect(container.read(commuteProvider).error, contains('ORS_API_KEY'));
    });

    test('reset clears state', () {
      final container = buildContainer(
        route: const RouteSummary(distanceMeters: 1000, durationSeconds: 600),
      );
      addTearDown(container.dispose);

      container.read(commuteProvider.notifier).reset();
      expect(container.read(commuteProvider), const CommuteState());
    });
  });

  group('geocodeAddress', () {
    test('returns null for short queries without searching', () async {
      final searchService = _StubLocationSearchService();

      final endpoint = await geocodeAddress('a', searchService);

      expect(endpoint, isNull);
      expect(searchService.lastQuery, isNull);
    });

    test('returns the first search result as a commute endpoint', () async {
      final searchService = _StubLocationSearchService(
        results: const [
          LocationSuggestion(
            displayName: 'AAST Alexandria, Egypt',
            shortName: 'AAST Alexandria',
            address: 'AAST Alexandria, Egypt',
            latitude: 31.3069,
            longitude: 30.0606,
          ),
          LocationSuggestion(
            displayName: 'Cairo University, Giza, Egypt',
            shortName: 'Cairo University',
            address: 'Cairo University, Giza, Egypt',
            latitude: 30.0276,
            longitude: 31.2104,
          ),
        ],
      );

      final endpoint = await geocodeAddress(
        '  AAST  ',
        searchService,
        biasLat: 30.05,
        biasLng: 31.24,
      );

      expect(endpoint, isNotNull);
      expect(endpoint!.label, 'AAST Alexandria');
      expect(endpoint.latitude, 31.3069);
      expect(endpoint.longitude, 30.0606);
      expect(searchService.lastQuery, 'AAST');
      expect(searchService.lastBiasLat, 30.05);
      expect(searchService.lastBiasLng, 31.24);
    });
  });
}
