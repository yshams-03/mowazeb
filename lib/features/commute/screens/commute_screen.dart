import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../locations/models/saved_location.dart';
import '../../locations/providers/locations_provider.dart';
import '../models/commute_result.dart';
import '../providers/commute_provider.dart';
import '../widgets/commute_loading_shimmer.dart';
import '../widgets/commute_verdict_card.dart';
import '../widgets/mosque_finder_section.dart';

class CommuteScreen extends ConsumerWidget {
  const CommuteScreen({super.key});

  SavedLocation? _findHome(List<SavedLocation> locations) {
    for (final loc in locations) {
      if (loc.kind == LocationKind.home) return loc;
    }
    return null;
  }

  String _homeLabel(SavedLocation? home, String? homeAddress, String? locationLabel) {
    if (home != null) return home.name;
    if (homeAddress != null && homeAddress.trim().isNotEmpty) {
      return homeAddress.trim();
    }
    return locationLabel ?? 'Home';
  }

  String? _homeAddressLine(SavedLocation? home, String? homeAddress) {
    if (home != null) return home.address;
    if (homeAddress != null && homeAddress.trim().isNotEmpty) {
      return homeAddress.trim();
    }
    return null;
  }

  Future<void> _calculate(BuildContext context, WidgetRef ref) async {
    final origin = await resolveCurrentLocationEndpoint();
    if (origin == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get your current location. Grant GPS permission and try again.',
          ),
        ),
      );
      return;
    }

    final destination = await resolveHomeEndpoint(ref);
    if (destination == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Home location not set. Add Home in My Places or Profile.',
          ),
          action: SnackBarAction(
            label: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ),
      );
      return;
    }

    await ref.read(commuteProvider.notifier).calculate(
          origin: origin!,
          destination: destination!,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeLocationSeederProvider);
    final commuteState = ref.watch(commuteProvider);
    final locationsAsync = ref.watch(savedLocationsProvider);
    final settings = ref.watch(userSettingsProvider).valueOrNull;

    final locations = locationsAsync.valueOrNull ?? [];
    final home = _findHome(locations);
    final homeLabel = _homeLabel(home, settings?.homeAddress, settings?.locationLabel);
    final homeAddress = _homeAddressLine(home, settings?.homeAddress);
    final hasHome = home != null ||
        (settings?.latitude != null && settings?.longitude != null) ||
        (settings?.homeAddress?.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Commute Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Can you reach home before the next prayer?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 20),
          const _RoutePointCard(
            icon: Icons.my_location,
            iconColor: AppColors.primaryTeal,
            title: 'From',
            label: 'Current location',
            subtitle: 'Your GPS position right now',
          ),
          const SizedBox(height: 12),
          _RoutePointCard(
            icon: Icons.home_outlined,
            iconColor: AppColors.accentGold,
            title: 'To',
            label: homeLabel,
            subtitle: homeAddress ?? 'Saved home from My Places',
            trailing: TextButton(
              onPressed: () => context.go(RoutePaths.places),
              child: const Text('My Places'),
            ),
          ),
          if (!hasHome) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.accentGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set your home in My Places (kind: Home) or Profile.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: commuteState.isLoading || !hasHome
                  ? null
                  : () => _calculate(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              child: commuteState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Can I Make It?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (commuteState.isLoading) const CommuteLoadingShimmer(),
          if (commuteState.error != null) ...[
            Card(
              color: AppColors.errorRed.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      commuteState.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: hasHome ? () => _calculate(context, ref) : null,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (commuteState.result != null) ...[
            CommuteVerdictCard(result: commuteState.result!),
            if (commuteState.result!.verdict == CommuteVerdict.red) ...[
              const SizedBox(height: 24),
              MosqueFinderSection(
                mosques: commuteState.result!.nearbyMosques,
              ),
            ],
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _RoutePointCard extends StatelessWidget {
  const _RoutePointCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.label,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String label;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
