import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prayer_log_entry.dart';
import '../providers/prayer_log_provider.dart';
import '../../prayer/models/prayer_time_model.dart';
import '../../prayer/providers/prayer_provider.dart';
import 'prayer_checkoff_icon.dart';
import 'status_toggle.dart';

class MemberPrayerRow extends ConsumerWidget {
  const MemberPrayerRow({
    super.key,
    required this.feed,
  });

  final MemberPrayerFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimes = ref.watch(prayerProvider.select((s) => s.todaysPrayers));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: feed.isCurrentUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                _initials(feed.displayName),
                style: TextStyle(
                  color: feed.isCurrentUser
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feed.isCurrentUser
                              ? '${feed.displayName} (You)'
                              : feed.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      StatusBadge(status: feed.presenceStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: PrayerName.values.map((prayer) {
                      var entry = feed.entries[prayer] ??
                          PrayerLogEntry(prayerName: prayer);

                      if (entry.status == PrayerLogStatus.missed &&
                          feed.presenceStatus.suppressesMissedAlerts) {
                        entry = entry.copyWith(status: PrayerLogStatus.pending);
                      }

                      final prayerTime = prayerTimes
                          .where((p) => p.name == prayer)
                          .firstOrNull;
                      final prayerHasPassed = prayerTime?.isPassed ?? false;

                      final canCheckOff = feed.isCurrentUser &&
                          !entry.checkedOff &&
                          entry.status != PrayerLogStatus.missed &&
                          prayerHasPassed;

                      return Expanded(
                        child: Center(
                          child: PrayerCheckoffIcon(
                            prayer: prayer,
                            entry: entry,
                            enabled: canCheckOff,
                            onTap: canCheckOff
                                ? () => ref
                                    .read(prayerLogNotifierProvider.notifier)
                                    .checkOff(prayer)
                                : null,
                            size: 28,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

extension _FirstOrNullMember<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

class PrayerLegend extends StatelessWidget {
  const PrayerLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(context, Colors.grey, 'Pending'),
        _legendItem(context, const Color(0xFF16A34A), 'Done'),
        _legendItem(context, const Color(0xFFDC2626), 'Missed'),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class PrayerColumnHeader extends StatelessWidget {
  const PrayerColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 8),
      child: Row(
        children: PrayerName.values
            .map(
              (prayer) => Expanded(
                child: Center(
                  child: Text(
                    _shortLabel(prayer),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _shortLabel(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Magh';
      case PrayerName.isha:
        return 'Isha';
    }
  }
}
