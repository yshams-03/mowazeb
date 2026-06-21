import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/widgets/prayer_times_panel.dart';
import '../../analytics/widgets/streak_widget.dart';
import '../../qibla/widgets/qibla_home_card.dart';
import '../widgets/ramadan_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidget());
  }

  void _syncWidget() {
    final prayerState = ref.read(prayerProvider);
    final prefs = ref.read(appPreferencesProvider);
    HomeWidgetService.startPeriodicUpdates(
      nextPrayer: prayerState.nextPrayer,
      todaysPrayers: prayerState.todaysPrayers,
      localeCode: prefs.localeCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen(prayerProvider, (_, __) => _syncWidget());
    ref.listen(appPreferencesProvider, (_, __) => _syncWidget());

    return RefreshIndicator(
      onRefresh: () => ref.read(prayerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              l10n.prayerTimes,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settings,
                onPressed: () => context.push(RoutePaths.settings),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshPrayerTimes,
                onPressed: () => ref.read(prayerProvider.notifier).refresh(),
              ),
            ],
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(child: RamadanBanner()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverToBoxAdapter(child: IftarCountdownCard()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: StreakWidget(),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: QiblaHomeCard(),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverToBoxAdapter(
              child: PrayerTimesPanel(),
            ),
          ),
        ],
      ),
    );
  }
}
