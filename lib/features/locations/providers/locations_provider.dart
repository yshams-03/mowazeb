import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_settings.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/saved_location.dart';
import '../services/location_search_service.dart';
import '../services/open_route_service.dart';
import '../services/reverse_geocode_service.dart';

final locationSearchServiceProvider = Provider<LocationSearchService>(
  (ref) => LocationSearchService(),
);

final reverseGeocodeServiceProvider = Provider<ReverseGeocodeService>(
  (ref) => ReverseGeocodeService(),
);

final openRouteServiceProvider = Provider<OpenRouteService>(
  (ref) => OpenRouteService(),
);

final savedLocationsProvider = StreamProvider<List<SavedLocation>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }

  return ref.watch(firestoreProvider).collection(FirestorePaths.savedLocations(user.uid)).orderBy('updatedAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => SavedLocation.fromFirestore(doc.id, doc.data()))
            .toList(),
      );
});

/// Backward-compatible alias used by planner and other features.
final locationsProvider = Provider<AsyncValue<List<SavedLocation>>>((ref) {
  return ref.watch(savedLocationsProvider);
});

final locationActionsProvider = Provider<LocationActions>((ref) {
  return LocationActions(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class LocationActions {
  LocationActions(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  bool _seededHome = false;

  Future<void> addLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required LocationKind kind,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef =
        _firestore.collection(FirestorePaths.savedLocations(user.uid)).doc();

    await docRef.set(
      SavedLocation(
        id: docRef.id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        kind: kind,
      ).toMap(),
    );
  }

  Future<void> updateLocation({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required LocationKind kind,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.doc(FirestorePaths.savedLocation(user.uid, id)).set(
          SavedLocation(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            kind: kind,
          ).toMap(),
        );
  }

  Future<void> deleteLocation(String locationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .doc(FirestorePaths.savedLocation(user.uid, locationId))
        .delete();
  }

  Future<void> maybeSeedHome(UserSettings settings) async {
    if (_seededHome) return;
    if (settings.latitude == null || settings.longitude == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final existing = await _firestore
        .collection(FirestorePaths.savedLocations(user.uid))
        .where('kind', isEqualTo: LocationKind.home.name)
        .limit(1)
        .get();

    _seededHome = true;
    if (existing.docs.isNotEmpty) return;

    await addLocation(
      name: 'Home',
      address: settings.locationLabel ??
          '${settings.latitude!.toStringAsFixed(4)}, '
              '${settings.longitude!.toStringAsFixed(4)}',
      latitude: settings.latitude!,
      longitude: settings.longitude!,
      kind: LocationKind.home,
    );
  }
}

final homeLocationSeederProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserSettings>>(userSettingsProvider, (_, next) {
    next.whenData((settings) {
      if (settings.isComplete) {
        ref.read(locationActionsProvider).maybeSeedHome(settings);
      }
    });
  });
});
