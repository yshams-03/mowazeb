import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../models/commute_result.dart';

class CommuteVerdictCard extends StatelessWidget {
  const CommuteVerdictCard({super.key, required this.result});

  final CommuteResult result;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    final arrival = timeFormat.format(result.estimatedArrival);
    final prayerTime = timeFormat.format(result.nextPrayerTime);
    final isGreen = result.verdict == CommuteVerdict.green;

    final message = isGreen
        ? "Safe to go! Drive time home is ~${result.drivingDurationMinutes} min and "
            '${result.nextPrayerName} is in ${result.minutesUntilPrayer} min — '
            "you'll arrive at $arrival with ${result.minutesBuffer} min to spare "
            'before prayer at $prayerTime.'
        : "Stop! Drive time home (~${result.drivingDurationMinutes} min) exceeds time "
            'until ${result.nextPrayerName} (${result.minutesUntilPrayer} min left). '
            "You'd arrive at $arrival — after prayer at $prayerTime. "
            'Pray before heading out!';

    return Card(
      color: isGreen
          ? AppColors.successGreen.withValues(alpha: 0.15)
          : AppColors.errorRed.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isGreen ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isGreen ? AppColors.successGreen : AppColors.errorRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGreen ? 'Safe to go' : 'Pray before you leave',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isGreen
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Drive time: ~${result.drivingDurationMinutes} min (ORS estimate)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
