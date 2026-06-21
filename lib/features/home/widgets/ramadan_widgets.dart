import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/utils/app_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../planner/providers/ramadan_provider.dart';
import '../../prayer/providers/prayer_provider.dart';

class RamadanBanner extends ConsumerWidget {
  const RamadanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ramadan = ref.watch(ramadanProvider);
    if (!ramadan.isActive || !ramadan.isFirstDay) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withValues(alpha: 0.25),
            AppColors.primaryTeal.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: AppColors.accentGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).ramadanMubarak,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class IftarCountdownCard extends ConsumerWidget {
  const IftarCountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ramadan = ref.watch(ramadanProvider);
    final countdown = ref.watch(timeUntilNextPrayerProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final l10n = AppLocalizations.of(context);

    if (!ramadan.isActive) return const SizedBox.shrink();

    final iftarRemaining = ramadan.iftarCountdown(DateTime.now());
    if (iftarRemaining == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3D99), AppColors.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.iftarCountdown,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          countdown.when(
            data: (_) => Text(
              AppFormat.duration(iftarRemaining, arabicNumerals: prefs.arabicNumerals),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            loading: () => const CircularProgressIndicator(color: AppColors.accentGold),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (ramadan.iftarTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.iftar}: ${DateFormat.jm().format(ramadan.iftarTime!)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
