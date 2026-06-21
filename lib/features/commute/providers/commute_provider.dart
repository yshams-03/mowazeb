import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/user_settings.dart';
import '../../auth/providers/auth_provider.dart';
import '../../locations/models/saved_location.dart';
import '../../locations/providers/locations_provider.dart';
import '../../locations/services/location_search_service.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../models/commute_result.dart';
import '../services/commute_calculator.dart';
import '../services/mosque_search_service.dart';

final mosqueSearchServiceProvider = Provider<MosqueSearchService>(
  (ref) => MosqueSearchService(),
);

class CommuteState {
  const CommuteState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  final bool isLoading;
  final CommuteResult? result;
  final String? error;

  CommuteState copyWith({
    bool? isLoading,
    CommuteResult? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CommuteState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CommuteNotifier extends StateNotifier<CommuteState> {
  CommuteNotifier(this._ref, {CommuteState? initialState})
      : super(initialState ?? const CommuteState());

  final Ref _ref;

  Future<void> calculate({
    required CommuteEndpoint origin,
    required CommuteEndpoint destination,
  }) async {
    state = state.copyWith(isLoading: true, clearResult: true, clearError: true);

    try {
      final ors = _ref.read(openRouteServiceProvider);
      if (!ors.isConfigured) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Routing is not configured. Add your free ORS_API_KEY to .env '
              '(sign up at openrouteservice.org).',
        );
        return;
      }

      final route = await ors.getDirections(
        startLat: origin.latitude,
        startLng: origin.longitude,
        endLat: destination.latitude,
        endLng: destination.longitude,
      );

      if (route == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not calculate route. Check your connection and retry.',
        );
        return;
      }

      final nextPrayer = _ref.read(prayerProvider).nextPrayer;
      if (nextPrayer == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Prayer times are not loaded yet. Pull to refresh and retry.',
        );
        return;
      }

      var mosques = const <MosqueResult>[];
      final preliminary = computeCommuteResult(
        now: DateTime.now(),
        route: route,
        nextPrayer: nextPrayer,
      );

      if (preliminary.verdict == CommuteVerdict.red) {
        mosques = await _ref.read(mosqueSearchServiceProvider).findNearbyMosques(
              latitude: origin.latitude,
              longitude: origin.longitude,
            );
      }

      final result = computeCommuteResult(
        now: DateTime.now(),
        route: route,
        nextPrayer: nextPrayer,
        nearbyMosques: mosques,
      );

      state = state.copyWith(isLoading: false, result: result);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() {
    if (!state.isLoading && state.result == null && state.error == null) return;
    state = const CommuteState();
  }
}

final commuteProvider =
    StateNotifierProvider<CommuteNotifier, CommuteState>((ref) {
  return CommuteNotifier(ref);
});

Future<CommuteEndpoint?> resolveCurrentLocationEndpoint() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return CommuteEndpoint(
      label: 'Current location',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (_) {
    return null;
  }
}

Future<CommuteEndpoint?> resolveHomeEndpoint(WidgetRef ref) async {
  return resolveHomeEndpointWith(
    locations: ref.read(savedLocationsProvider).valueOrNull ?? [],
    settings: ref.read(userSettingsProvider).valueOrNull,
    searchService: ref.read(locationSearchServiceProvider),
  );
}

Future<CommuteEndpoint?> resolveHomeEndpointWith({
  required List<SavedLocation> locations,
  required UserSettings? settings,
  required LocationSearchService searchService,
}) async {
  for (final loc in locations) {
    if (loc.kind == LocationKind.home) {
      return CommuteEndpoint(
        label: loc.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
    }
  }

  if (settings?.latitude != null && settings?.longitude != null) {
    return CommuteEndpoint(
      label: settings!.homeAddress ?? settings.locationLabel ?? 'Home',
      latitude: settings.latitude!,
      longitude: settings.longitude!,
    );
  }

  final homeAddress = settings?.homeAddress?.trim();
  if (homeAddress != null && homeAddress.isNotEmpty) {
    return geocodeAddress(
      homeAddress,
      searchService,
      biasLat: settings?.latitude,
      biasLng: settings?.longitude,
    );
  }

  return null;
}

Future<CommuteEndpoint?> geocodeAddress(
  String query,
  LocationSearchService searchService, {
  double? biasLat,
  double? biasLng,
}) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return null;

  final results = await searchService.search(
    trimmed,
    biasLat: biasLat,
    biasLng: biasLng,
  );
  if (results.isEmpty) return null;

  final first = results.first;
  return CommuteEndpoint(
    label: first.shortName,
    latitude: first.latitude,
    longitude: first.longitude,
  );
}
