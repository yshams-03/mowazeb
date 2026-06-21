import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/prayer_time_model.dart';

extension PrayerNameL10n on PrayerName {
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      PrayerName.fajr => l10n.prayerFajr,
      PrayerName.dhuhr => l10n.prayerDhuhr,
      PrayerName.asr => l10n.prayerAsr,
      PrayerName.maghrib => l10n.prayerMaghrib,
      PrayerName.isha => l10n.prayerIsha,
    };
  }
}
