import 'package:cloud_firestore/cloud_firestore.dart';

enum LocationKind {
  home,
  work,
  other;

  String get label {
    switch (this) {
      case LocationKind.home:
        return 'Home';
      case LocationKind.work:
        return 'Work';
      case LocationKind.other:
        return 'Other';
    }
  }

  static LocationKind fromString(String? value) {
    switch (value) {
      case 'home':
        return LocationKind.home;
      case 'work':
        return LocationKind.work;
      default:
        return LocationKind.other;
    }
  }
}

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.kind = LocationKind.other,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final LocationKind kind;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'kind': kind.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedLocation.fromFirestore(String id, Map<String, dynamic> data) {
    final updatedRaw = data['updatedAt'];
    DateTime? updatedAt;
    if (updatedRaw is Timestamp) {
      updatedAt = updatedRaw.toDate();
    } else if (updatedRaw is String) {
      updatedAt = DateTime.tryParse(updatedRaw);
    }

    return SavedLocation(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      kind: LocationKind.fromString(data['kind'] as String?),
      updatedAt: updatedAt,
    );
  }

  SavedLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    LocationKind? kind,
    DateTime? updatedAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kind: kind ?? this.kind,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
