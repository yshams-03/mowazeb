import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/dua_provider.dart';

class PostDuaSheet extends ConsumerStatefulWidget {
  const PostDuaSheet({super.key, required this.circleId});

  final String circleId;

  static Future<void> show(BuildContext context, {required String circleId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PostDuaSheet(circleId: circleId),
      ),
    );
  }

  @override
  ConsumerState<PostDuaSheet> createState() => _PostDuaSheetState();
}

class _PostDuaSheetState extends ConsumerState<PostDuaSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isPosting) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      final authorName = user.displayName ?? user.email ?? 'Member';
      await ref.read(duaActionsProvider).postRequest(
            circleId: widget.circleId,
            message: message,
            authorName: authorName,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post request. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Post Dua Request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Share an intention with your circle. Only the message is visible — keep personal details private.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 280,
              decoration: const InputDecoration(
                hintText: 'e.g. Dua for my upcoming exam',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isPosting || _controller.text.trim().isEmpty
                  ? null
                  : _post,
              child: _isPosting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post Request'),
            ),
          ],
        ),
      ),
    );
  }
}
