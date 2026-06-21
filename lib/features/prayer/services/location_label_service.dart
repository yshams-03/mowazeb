import 'package:geocoding/geocoding.dart';

Future<String?> resolveLocationLabel(double latitude, double longitude) async {
  try {
    final places = await placemarkFromCoordinates(latitude, longitude);
    if (places.isEmpty) return null;

    final place = places.first;
    final parts = [
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
  } catch (_) {
    return null;
  }
}
