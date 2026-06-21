import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/circles_provider.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _createdInviteCode;
  String? _createdCircleId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final result = await ref.read(circleActionsProvider).createCircle(name);
      if (!mounted) return;

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Could not create circle.')),
        );
        return;
      }

      setState(() {
        _createdCircleId = result.circleId;
        _createdInviteCode = result.inviteCode;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create circle: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Circle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _createdInviteCode != null
            ? _SuccessView(
                inviteCode: _createdInviteCode!,
                onOpenCircle: () {
                  context.go('${RoutePaths.communityCircle}/${_createdCircleId!}');
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Give your circle a name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share the invite code with family or friends so they can join.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Circle name',
                      hintText: 'e.g. Family, Masjid Group',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _create(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _create,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Circle'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.inviteCode,
    required this.onOpenCircle,
  });

  final String inviteCode;
  final VoidCallback onOpenCircle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: AppColors.successGreen, size: 56),
        const SizedBox(height: 16),
        Text(
          'Circle created!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Invite code',
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SelectableText(
          inviteCode,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invite code copied')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy code'),
        ),
        const Spacer(),
        FilledButton(
          onPressed: onOpenCircle,
          child: const Text('Open Circle Feed'),
        ),
      ],
    );
  }
}
