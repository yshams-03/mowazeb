import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/badge_grid.dart';
import '../widgets/streak_widget.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.lock_outline, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSnapshotProvider);
          await ref.read(analyticsSnapshotProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PrivateBanner(),
            const SizedBox(height: 16),
            const StreakWidget(),
            const SizedBox(height: 24),
            Text(
              l10n.badges,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            const BadgeGrid(),
            const SizedBox(height: 24),
            snapshotAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Analytics error: $e'),
              data: (snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(title: 'Prayer completion (30 days)'),
                  CompletionChart(data: snapshot.dailyCompletions),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Per-prayer timing'),
                  PrayerTimingChart(stats: snapshot.prayerDelays),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Schedule insights'),
                  ...snapshot.insights.map(
                    (insight) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(insight.message),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Weekly heatmap (8 weeks)'),
                  WeeklyHeatmap(cells: snapshot.heatmap),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, size: 18, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.privateAnalytics,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
