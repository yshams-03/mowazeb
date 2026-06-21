import 'location_suggestion.dart';

class MapPickerResult {
  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.shortName,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String shortName;

  LocationSuggestion toLocationSuggestion() {
    return LocationSuggestion(
      displayName: address,
      shortName: shortName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
