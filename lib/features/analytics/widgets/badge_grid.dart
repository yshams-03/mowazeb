import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badge_model.dart';
import '../providers/analytics_provider.dart';

class BadgeGrid extends ConsumerWidget {
  const BadgeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedBadgeIdsProvider);
    final badgesAsync = ref.watch(userBadgesProvider);

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Badges error: $e'),
      data: (_) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: BadgeDefinition.all.length,
          itemBuilder: (context, index) {
            final def = BadgeDefinition.all[index];
            final isUnlocked = unlocked.contains(def.id);
            return _BadgeTile(definition: def, unlocked: isUnlocked);
          },
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.definition, required this.unlocked});

  final BadgeDefinition definition;
  final bool unlocked;

  IconData get _icon {
    switch (definition.id) {
      case BadgeId.dawnWarrior:
      case BadgeId.dawnWarrior30:
        return Icons.wb_sunny_outlined;
      case BadgeId.perfectWeek:
        return Icons.emoji_events_outlined;
      case BadgeId.earlyBird:
        return Icons.alarm_outlined;
      case BadgeId.nightOwl:
        return Icons.nightlight_outlined;
      case BadgeId.circleChampion:
        return Icons.groups_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: unlocked
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon,
              color: unlocked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 28,
            ),
            const Spacer(),
            Text(
              definition.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unlocked ? null : Colors.grey,
                  ),
            ),
            Text(
              definition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: unlocked
                        ? Theme.of(context).hintColor
                        : Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
