import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/locations/models/saved_location.dart';

void main() {
  group('SavedLocation', () {
    test('testFromFirestoreRoundtrip', () {
      final map = {
        'name': 'University',
        'address': 'AAST, Alexandria, Egypt',
        'latitude': 31.3069,
        'longitude': 30.0606,
        'kind': 'other',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 21)),
      };

      final location = SavedLocation.fromFirestore('loc-1', map);
      final serialized = location.copyWith(id: 'loc-1').toMap()
        ..remove('updatedAt');

      expect(location.id, 'loc-1');
      expect(location.name, 'University');
      expect(location.address, 'AAST, Alexandria, Egypt');
      expect(location.latitude, 31.3069);
      expect(location.longitude, 30.0606);
      expect(location.kind, LocationKind.other);
      expect(serialized['name'], 'University');
      expect(serialized['kind'], 'other');
    });

    test('testKindParsing', () {
      expect(
        SavedLocation.fromFirestore('1', {'kind': 'home'}).kind,
        LocationKind.home,
      );
      expect(
        SavedLocation.fromFirestore('1', {'kind': 'work'}).kind,
        LocationKind.work,
      );
      expect(
        SavedLocation.fromFirestore('1', {'kind': 'other'}).kind,
        LocationKind.other,
      );
      expect(
        SavedLocation.fromFirestore('1', {'kind': 'unknown'}).kind,
        LocationKind.other,
      );
    });
  });
}
