class LocationSuggestion {
  const LocationSuggestion({
    required this.displayName,
    required this.shortName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final String shortName;
  final String address;
  final double latitude;
  final double longitude;

  factory LocationSuggestion.fromNominatim(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final shortName = displayName.contains(',')
        ? displayName.split(',').first.trim()
        : displayName.trim();

    return LocationSuggestion(
      displayName: displayName,
      shortName: shortName.isNotEmpty ? shortName : displayName,
      address: displayName,
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
    );
  }
}
