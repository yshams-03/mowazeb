import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/circles_provider.dart';
import '../screens/dua_board_screen.dart';
import '../widgets/member_prayer_row.dart';
import '../widgets/status_toggle.dart';

class CircleDetailScreen extends ConsumerWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(circleProvider(circleId));
    final feedAsync = ref.watch(circleFeedProvider(circleId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: circleAsync.when(
            data: (circle) => Text(circle?.name ?? 'Circle'),
            loading: () => const Text('Circle'),
            error: (_, __) => const Text('Circle'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Prayer Feed'),
              Tab(text: 'Dua Board'),
            ],
          ),
          actions: [
            circleAsync.whenOrNull(
              data: (circle) {
                if (circle == null) return null;
                return IconButton(
                  tooltip: 'Copy invite code',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: circle.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invite code ${circle.inviteCode} copied'),
                      ),
                    );
                  },
                );
              },
            ) ??
                const SizedBox.shrink(),
          ],
        ),
        body: circleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (circle) {
            if (circle == null) {
              return const Center(child: Text('Circle not found'));
            }

            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(circleFeedProvider(circleId));
                    await ref.read(circleFeedProvider(circleId).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: AppColors.accentGold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Group streak: ${circle.groupStreak} days',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${circle.members.length} members · Code ${circle.inviteCode}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const StatusToggle(compact: true),
                      const SizedBox(height: 16),
                      Text(
                        "Today's prayer feed",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const PrayerLegend(),
                      const SizedBox(height: 12),
                      const PrayerColumnHeader(),
                      feedAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Text('Feed error: $error'),
                        data: (feeds) {
                          if (feeds.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No members in this circle yet.'),
                            );
                          }

                          return Column(
                            children: feeds
                                .map((feed) => MemberPrayerRow(feed: feed))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                DuaBoardScreen(circleId: circleId),
              ],
            );
          },
        ),
      ),
    );
  }
}
