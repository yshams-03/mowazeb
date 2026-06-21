import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_status.dart';
import '../providers/status_provider.dart';

class StatusToggle extends ConsumerStatefulWidget {
  const StatusToggle({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends ConsumerState<StatusToggle> {
  bool _isSaving = false;
  int? _expiryHours;

  Future<void> _save(UserPresenceStatus status) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(statusActionsProvider).setStatus(
            status: status,
            expiresAfter: _expiryHours != null
                ? Duration(hours: _expiryHours!)
                : null,
          );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(currentUserStatusProvider);
    final effective = statusAsync.valueOrNull?.effectiveStatus ??
        UserPresenceStatus.active;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 4),
              Text(
                'Circle members see only the label — never private details.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserPresenceStatus.values.map((status) {
                final selected = effective == status;
                return ChoiceChip(
                  label: Text(status.publicLabel),
                  selected: selected,
                  onSelected: _isSaving
                      ? null
                      : (_) {
                          if (status == UserPresenceStatus.active) {
                            setState(() => _expiryHours = null);
                          }
                          _save(status);
                        },
                );
              }).toList(),
            ),
            if (effective != UserPresenceStatus.active) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: _expiryHours,
                decoration: const InputDecoration(
                  labelText: 'Auto-reset after',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('No expiry')),
                  DropdownMenuItem(value: 1, child: Text('1 hour')),
                  DropdownMenuItem(value: 4, child: Text('4 hours')),
                  DropdownMenuItem(value: 8, child: Text('8 hours')),
                  DropdownMenuItem(value: 24, child: Text('24 hours')),
                ],
                onChanged: _isSaving
                    ? null
                    : (hours) {
                        setState(() => _expiryHours = hours);
                        _save(effective);
                      },
              ),
            ],
            if (_isSaving) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final UserPresenceStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == UserPresenceStatus.active) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.publicLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
