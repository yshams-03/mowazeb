import '../../../features/locations/services/open_route_service.dart';
import '../../../features/prayer/models/prayer_time_model.dart';
import '../models/commute_result.dart';

CommuteResult computeCommuteResult({
  required DateTime now,
  required RouteSummary route,
  required PrayerTimeModel nextPrayer,
  List<MosqueResult> nearbyMosques = const [],
}) {
  final drivingMinutes = route.durationMinutes;
  final driveTime = Duration(seconds: route.durationSeconds.round());
  final timeUntilPrayer = nextPrayer.time.difference(now);
  final minutesUntilPrayer = timeUntilPrayer.inMinutes.clamp(0, 9999);
  final arrival = now.add(driveTime);

  // RED when drive time exceeds the live next-prayer countdown.
  final canMakeIt =
      !timeUntilPrayer.isNegative && driveTime <= timeUntilPrayer;
  final verdict =
      canMakeIt ? CommuteVerdict.green : CommuteVerdict.red;

  final spareSeconds = timeUntilPrayer.inSeconds - driveTime.inSeconds;
  final minutesBuffer = (spareSeconds / 60).floor();

  return CommuteResult(
    estimatedArrival: arrival,
    drivingDurationMinutes: drivingMinutes,
    minutesUntilPrayer: minutesUntilPrayer,
    nextPrayerName: nextPrayer.name.displayName,
    nextPrayerTime: nextPrayer.time,
    minutesBuffer: minutesBuffer,
    verdict: verdict,
    nearbyMosques: verdict == CommuteVerdict.red ? nearbyMosques : const [],
  );
}
