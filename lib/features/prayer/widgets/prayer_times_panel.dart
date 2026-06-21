import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/models/prayer_log_entry.dart';
import '../../community/providers/prayer_log_provider.dart';
import '../../community/widgets/prayer_checkoff_icon.dart';
import '../models/prayer_time_model.dart';
import '../providers/hijri_date_provider.dart';
import '../providers/prayer_provider.dart';

class PrayerTimesPanel extends ConsumerWidget {
  const PrayerTimesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerProvider);
    final countdown = ref.watch(timeUntilNextPrayerProvider);
    final prayerLogs = ref.watch(prayerLogNotifierProvider);
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final hijriAsync = ref.watch(hijriDateProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final panelColor = isDark ? const Color(0xFF2A2F36) : const Color(0xFF3D4550);
    final rowColor = isDark ? const Color(0xFF353C45) : const Color(0xFF4A5360);

    if (prayerState.isLoading) {
      return _PanelShell(
        color: panelColor,
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          ),
        ),
      );
    }

    if (prayerState.error != null) {
      return _PanelShell(
        color: panelColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                prayerState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(prayerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final gregorian = DateFormat('EEE, d MMMM').format(now);
    final hijriLabel = hijriAsync.when(
      data: (hijri) => isArabic
          ? hijri.formatArabic(arabicNumerals: prefs.arabicNumerals)
          : hijri.formatEnglish(),
      loading: () => null,
      error: (_, __) => null,
    );
    final locationLabel = settings?.locationLabel ??
        _coordinatesLabel(settings?.latitude, settings?.longitude);

    return _PanelShell(
      color: panelColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gregorian,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hijriLabel != null && hijriLabel.isNotEmpty)
                        Text(
                          hijriLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                        ),
                      if (prayerState.isHighLatitudeEstimate) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Estimated times (high latitude)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (locationLabel != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: prayerState.todaysPrayers.map((prayer) {
                  final isNext = prayer.isNext;
                  final entry = prayerLogs[prayer.name] ??
                      PrayerLogEntry(prayerName: prayer.name);
                  return _PrayerRow(
                    prayer: prayer,
                    isNext: isNext,
                    countdown: isNext ? countdown : null,
                    logEntry: entry,
                    onCheckOff: entry.checkedOff || !prayer.isPassed
                        ? null
                        : () => ref
                            .read(prayerLogNotifierProvider.notifier)
                            .checkOff(prayer.name),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _coordinatesLabel(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.isNext,
    required this.logEntry,
    this.countdown,
    this.onCheckOff,
  });

  final PrayerTimeModel prayer;
  final bool isNext;
  final PrayerLogEntry logEntry;
  final AsyncValue<Duration>? countdown;
  final VoidCallback? onCheckOff;

  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.75),
      fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
      fontSize: 15,
      decoration: prayer.isPassed ? TextDecoration.lineThrough : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(prayer.name.displayName, style: nameStyle),
          ),
          Expanded(
            child: isNext
                ? countdown?.when(
                      data: (remaining) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCountdownCompact(remaining),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'left',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      loading: () => Text(
                        formatCountdownCompact(
                          prayer.time.difference(DateTime.now()),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ) ??
                    const SizedBox.shrink()
                : const SizedBox.shrink(),
          ),
          isNext
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prayer.compactFormattedTime,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                )
              : Text(
                  prayer.compactFormattedTime,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
          const SizedBox(width: 8),
          PrayerCheckoffIcon(
            prayer: prayer.name,
            entry: logEntry,
            enabled: onCheckOff != null,
            onTap: onCheckOff,
            size: 26,
          ),
        ],
      ),
    );
  }
}
