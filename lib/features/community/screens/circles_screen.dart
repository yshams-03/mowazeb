import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/circles_provider.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circlesAsync = ref.watch(userCirclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountability Circles'),
      ),
      body: circlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load circles: $error'),
        ),
        data: (circles) {
          if (circles.isEmpty) {
            return _EmptyState(
              onCreate: () => context.push(RoutePaths.communityCreate),
              onJoin: () => context.push(RoutePaths.communityJoin),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pray together. Stay accountable.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 16),
              ...circles.map(
                (circle) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                      child: const Icon(Icons.groups, color: AppColors.primaryGreen),
                    ),
                    title: Text(circle.name),
                    subtitle: Text(
                      '${circle.members.length} members · Streak ${circle.groupStreak}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('${RoutePaths.communityCircle}/${circle.id}'),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join_circle',
            onPressed: () => context.push(RoutePaths.communityJoin),
            backgroundColor: AppColors.primaryTeal,
            icon: const Icon(Icons.login),
            label: const Text('Join Circle'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_circle',
            onPressed: () => context.push(RoutePaths.communityCreate),
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.add),
            label: const Text('Create Circle'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onCreate,
    required this.onJoin,
  });

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No circles yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a circle for your family or friends, or join one with an invite code.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Circle'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.login),
              label: const Text('Join Circle'),
            ),
          ],
        ),
      ),
    );
  }
}
