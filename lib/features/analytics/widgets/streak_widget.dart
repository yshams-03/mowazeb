import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/analytics_provider.dart';
import '../services/streak_cache_service.dart';

class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(personalStreakProvider);
    final cacheAsync = ref.watch(streakCacheServiceProvider);

    final streak = streakAsync.valueOrNull;
    final cachedCurrent = cacheAsync.valueOrNull?.cachedCurrent ?? 0;
    final cachedLongest = cacheAsync.valueOrNull?.cachedLongest ?? 0;

    final current = streak?.currentStreak ?? cachedCurrent;
    final longest = streak?.longestStreak ?? cachedLongest;

    if (compact) {
      return _CompactStreak(current: current, longest: longest);
    }

    return Card(
      color: AppColors.primaryGreen.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: current > 0 ? AppColors.accentGold : Colors.grey,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$current day streak',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                  ),
                  Text(
                    'Personal best: $longest days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _CompactStreak extends StatelessWidget {
  const _CompactStreak({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          color: current > 0 ? AppColors.accentGold : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '$current',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          ' · best $longest',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      ],
    );
  }
}
