import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/core/constants/app_constants.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';
import 'package:ummah_pulse/features/locations/providers/locations_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('LocationActions extended', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late LocationActions actions;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'uid-loc'), signedIn: true);
      actions = LocationActions(firestore, auth);
    });

    test('addLocation writes all fields to Firestore', () async {
      await actions.addLocation(
        name: 'Gym',
        address: 'Nasr City, Cairo',
        latitude: 30.01,
        longitude: 31.01,
        kind: LocationKind.other,
      );

      final snap = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .get();

      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['name'], 'Gym');
      expect(data['latitude'], 30.01);
      expect(data['longitude'], 31.01);
      expect(data['kind'], 'other');
      expect(data['updatedAt'], isNotNull);
    });

    test('deleteLocation removes the document', () async {
      await actions.addLocation(
        name: 'Work',
        address: 'Downtown',
        latitude: 30.02,
        longitude: 31.02,
        kind: LocationKind.work,
      );
      await actions.addLocation(
        name: 'Gym',
        address: 'Nasr City',
        latitude: 30.03,
        longitude: 31.03,
        kind: LocationKind.other,
      );

      final all = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .get();
      final toDelete = all.docs.firstWhere((d) => d.data()['name'] == 'Work');

      await actions.deleteLocation(toDelete.id);

      final remaining = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.data()['name'], 'Gym');
    });

    test('updateLocation overwrites existing document', () async {
      await actions.addLocation(
        name: 'Old Name',
        address: 'Old address',
        latitude: 30.0,
        longitude: 31.0,
        kind: LocationKind.home,
      );

      final doc = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .get();

      await actions.updateLocation(
        id: doc.docs.first.id,
        name: 'New Home',
        address: 'New address',
        latitude: 30.05,
        longitude: 31.05,
        kind: LocationKind.home,
      );

      final updated = await doc.docs.first.reference.get();
      expect(updated.data()?['name'], 'New Home');
      expect(updated.data()?['latitude'], 30.05);
    });

    test('maybeSeedHome creates home when none exists', () async {
      await actions.maybeSeedHome(cairoSettings());

      final snap = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .where('kind', isEqualTo: LocationKind.home.name)
          .get();

      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['latitude'], testLatitude);
      expect(snap.docs.first.data()['longitude'], testLongitude);
    });

    test('maybeSeedHome skips when home already exists', () async {
      await actions.addLocation(
        name: 'Existing Home',
        address: 'Home',
        latitude: 1,
        longitude: 2,
        kind: LocationKind.home,
      );

      await actions.maybeSeedHome(cairoSettings());

      final snap = await firestore
          .collection(FirestorePaths.savedLocations('uid-loc'))
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['name'], 'Existing Home');
    });
  });
}
