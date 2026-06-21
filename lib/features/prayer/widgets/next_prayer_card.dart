import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/prayer_provider.dart';

class NextPrayerCard extends ConsumerWidget {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerProvider);
    final countdown = ref.watch(timeUntilNextPrayerProvider);

    if (prayerState.isLoading) {
      return const _NextPrayerCardShell(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (prayerState.error != null) {
      return _NextPrayerCardShell(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              Text(
                prayerState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(prayerProvider.notifier).refresh(),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final nextPrayer = prayerState.nextPrayer;

    return _NextPrayerCardShell(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nextPrayer != null ? 'Next Prayer' : 'All Prayers Complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 8),
            if (nextPrayer != null) ...[
              Text(
                nextPrayer.name.displayName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                nextPrayer.formattedTime,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 24),
              countdown.when(
                data: (duration) => Text(
                  formatDuration(duration),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                loading: () => const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentGold,
                  ),
                ),
                error: (_, __) => const Text(
                  '--',
                  style: TextStyle(color: AppColors.accentGold, fontSize: 28),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
            ] else ...[
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'See you at Fajr tomorrow',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextPrayerCardShell extends StatelessWidget {
  const _NextPrayerCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
