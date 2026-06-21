import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dua_request.dart';
import '../providers/dua_provider.dart';
import '../widgets/post_dua_sheet.dart';

class DuaBoardScreen extends ConsumerWidget {
  const DuaBoardScreen({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(duaRequestsProvider(circleId));
    final currentUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Stack(
      children: [
        requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (requests) {
            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Dua requests yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share an intention and your circle can make Dua for you.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _DuaRequestCard(
                  circleId: circleId,
                  request: requests[index],
                  currentUid: currentUid,
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => PostDuaSheet.show(context, circleId: circleId),
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.add),
            label: const Text('Post Request'),
          ),
        ),
      ],
    );
  }
}

class _DuaRequestCard extends ConsumerStatefulWidget {
  const _DuaRequestCard({
    required this.circleId,
    required this.request,
    required this.currentUid,
  });

  final String circleId;
  final DuaRequest request;
  final String? currentUid;

  @override
  ConsumerState<_DuaRequestCard> createState() => _DuaRequestCardState();
}

class _DuaRequestCardState extends ConsumerState<_DuaRequestCard> {
  bool _isSending = false;

  Future<void> _makeDua() async {
    if (_isSending || widget.currentUid == null) return;
    if (widget.request.hasSentDua(widget.currentUid!)) return;
    if (widget.request.authorUid == widget.currentUid) return;

    setState(() => _isSending = true);
    try {
      await ref.read(duaActionsProvider).sendDua(
            circleId: widget.circleId,
            requestId: widget.request.id,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send Dua. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = widget.currentUid != null &&
        widget.request.hasSentDua(widget.currentUid!);
    final isAuthor = widget.currentUid == widget.request.authorUid;
    final timeLabel = DateFormat.MMMd().add_jm().format(widget.request.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.request.authorName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.request.message),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.request.duaSenders.length} making Dua',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                if (!isAuthor)
                  FilledButton.tonal(
                    onPressed: sent || _isSending ? null : _makeDua,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(sent ? 'Dua Sent ✓' : '🤲 Make Dua'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
