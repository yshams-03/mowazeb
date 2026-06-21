enum CommuteVerdict {
  green,
  red;

  bool get isSafe => this == CommuteVerdict.green;
}

class CommuteResult {
  const CommuteResult({
    required this.estimatedArrival,
    required this.drivingDurationMinutes,
    required this.minutesUntilPrayer,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.minutesBuffer,
    required this.verdict,
    this.nearbyMosques = const [],
  });

  final DateTime estimatedArrival;
  final int drivingDurationMinutes;
  /// Minutes remaining on the next-prayer countdown when the check ran.
  final int minutesUntilPrayer;
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  /// Spare minutes: countdown minus drive time (negative = route exceeds timer).
  final int minutesBuffer;
  final CommuteVerdict verdict;
  final List<MosqueResult> nearbyMosques;
}

class MosqueResult {
  const MosqueResult({
    required this.name,
    required this.address,
    required this.distanceMeters,
    required this.placeId,
    required this.googleMapsUrl,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final int distanceMeters;
  final String placeId;
  final String googleMapsUrl;
  final double latitude;
  final double longitude;

  String get formattedDistance {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class CommuteEndpoint {
  const CommuteEndpoint({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}
