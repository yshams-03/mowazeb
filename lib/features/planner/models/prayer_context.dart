import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

enum PrayerTag {
  atHome,
  atLocation,
  transition,
}

extension PrayerTagX on PrayerTag {
  Color get summaryColor {
    switch (this) {
      case PrayerTag.atHome:
        return AppColors.successGreen;
      case PrayerTag.atLocation:
        return const Color(0xFF3B82F6);
      case PrayerTag.transition:
        return AppColors.accentGold;
    }
  }

  String displayLabel({String? blockTitle, String? blockLocation}) {
    switch (this) {
      case PrayerTag.atHome:
        return '🏠 Pray at home';
      case PrayerTag.atLocation:
        final place = blockLocation ?? blockTitle ?? 'your location';
        return '📍 Pray at $place';
      case PrayerTag.transition:
        return '🔄 Transition — plan ahead';
    }
  }

  String get emoji {
    switch (this) {
      case PrayerTag.atHome:
        return '🏠';
      case PrayerTag.atLocation:
        return '📍';
      case PrayerTag.transition:
        return '🔄';
    }
  }
}

class PrayerContext {
  const PrayerContext({
    required this.prayerName,
    required this.prayerTime,
    required this.tag,
    this.blockTitle,
    this.blockLocation,
    this.wuduNudgeTime,
  });

  final String prayerName;
  final DateTime prayerTime;
  final PrayerTag tag;
  final String? blockTitle;
  final String? blockLocation;
  final DateTime? wuduNudgeTime;

  String get displayTag =>
      tag.displayLabel(blockTitle: blockTitle, blockLocation: blockLocation);

  String? wuduNotificationBody(String endingBlockTitle) {
    if (tag != PrayerTag.transition || wuduNudgeTime == null) return null;
    final minutesUntilPrayer = prayerTime.difference(wuduNudgeTime!).inMinutes;
    return 'You finish $endingBlockTitle in $minutesUntilPrayer minutes. '
        'Make Wudu now before ${blockLocation ?? 'the location'} gets crowded!';
  }
}
