import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/ramadan_provider.dart';

class RamadanMealPlan extends ConsumerWidget {
  const RamadanMealPlan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ramadan = ref.watch(ramadanProvider);
    if (!ramadan.isActive ||
        ramadan.suhoorTime == null ||
        ramadan.iftarTime == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final timeFormat = DateFormat.jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ramadanMode,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.wb_twilight, color: Color(0xFF5C3D99)),
            title: Text(l10n.suhoor),
            subtitle: Text(timeFormat.format(ramadan.suhoorTime!)),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: AppColors.primaryTeal),
            title: Text(l10n.iftar),
            subtitle: Text(timeFormat.format(ramadan.iftarTime!)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
