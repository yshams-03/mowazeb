import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../models/prayer_log_entry.dart';
import '../../prayer/models/prayer_time_model.dart';

class PrayerCheckoffIcon extends StatelessWidget {
  const PrayerCheckoffIcon({
    super.key,
    required this.prayer,
    required this.entry,
    this.enabled = false,
    this.onTap,
    this.size = 32,
  });

  final PrayerName prayer;
  final PrayerLogEntry entry;
  final bool enabled;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _iconColor();
    final icon = _iconData();

    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );

    if (!enabled || onTap == null) {
      return Tooltip(
        message: '${prayer.displayName}: ${entry.status.value}',
        child: child,
      );
    }

    return Tooltip(
      message: 'Check off ${prayer.displayName}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  Color _iconColor() {
    switch (entry.status) {
      case PrayerLogStatus.completed:
        return AppColors.successGreen;
      case PrayerLogStatus.missed:
        return AppColors.errorRed;
      case PrayerLogStatus.excused:
        return AppColors.accentGold;
      case PrayerLogStatus.pending:
        return Colors.grey;
    }
  }

  IconData _iconData() {
    switch (entry.status) {
      case PrayerLogStatus.completed:
        return Icons.check_circle;
      case PrayerLogStatus.missed:
        return Icons.cancel;
      case PrayerLogStatus.excused:
        return Icons.event_busy;
      case PrayerLogStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }
}
