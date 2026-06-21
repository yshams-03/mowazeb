import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_context.dart';

class DailyPrayerSummary extends StatelessWidget {
  const DailyPrayerSummary({
    super.key,
    required this.contexts,
  });

  final List<PrayerContext> contexts;

  @override
  Widget build(BuildContext context) {
    if (contexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Prayer Plan",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...contexts.map((ctx) => _SummaryRow(prayerContext: ctx)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.prayerContext});

  final PrayerContext prayerContext;

  @override
  Widget build(BuildContext context) {
    final color = prayerContext.tag.summaryColor;
    final timeLabel = DateFormat('h:mm a').format(prayerContext.prayerTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerContext.prayerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prayerContext.displayTag,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              timeLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
