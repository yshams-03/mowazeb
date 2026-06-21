import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../locations/models/saved_location.dart';
import '../../locations/providers/locations_provider.dart';
import '../models/routine_block.dart';
import '../providers/planner_provider.dart';
import '../services/planner_engine.dart';

class AddBlockSheet extends ConsumerStatefulWidget {
  const AddBlockSheet({super.key, this.existingBlock});

  final RoutineBlock? existingBlock;

  bool get isEditing => existingBlock != null;

  static Future<RoutineBlock?> show(
    BuildContext context, {
    RoutineBlock? existingBlock,
  }) {
    return showModalBottomSheet<RoutineBlock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddBlockSheet(existingBlock: existingBlock),
    );
  }

  @override
  ConsumerState<AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends ConsumerState<AddBlockSheet> {
  final _titleController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  late Set<int> _selectedDays;
  SavedLocation? _selectedLocation;
  bool _didPrefillLocation = false;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBlock;
    if (existing != null) {
      _titleController.text = existing.title;
      _startTime = existing.startTime;
      _endTime = existing.endTime;
      _selectedColor = existing.color;
      _selectedDays = existing.daysOfWeek.toSet();
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _selectedColor = RoutineBlockColors.presets.first;
      final today = weekdayIndex(DateTime.now());
      _selectedDays = {0, 1, 2, 3, 4, today};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _prefillLocation(List<SavedLocation> locations) {
    if (_didPrefillLocation || widget.existingBlock?.locationId == null) {
      return;
    }
    for (final location in locations) {
      if (location.id == widget.existingBlock!.locationId) {
        _didPrefillLocation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedLocation = location);
        });
        break;
      }
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedLocation == null || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title, location, and days.')),
      );
      return;
    }

    if (_endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    Navigator.of(context).pop(
      RoutineBlock(
        id: widget.existingBlock?.id ?? '',
        title: title,
        location: _selectedLocation!.name,
        locationId: _selectedLocation!.id,
        startTime: _startTime,
        endTime: _endTime,
        daysOfWeek: _selectedDays.toList()..sort(),
        color: _selectedColor,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final block = widget.existingBlock;
    if (block == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete block?'),
        content: Text('Remove "${block.title}" from your weekly schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(plannerProvider.notifier).deleteBlock(block.id);
    if (mounted) Navigator.of(context).pop();
  }

  IconData _iconFor(LocationKind kind) {
    switch (kind) {
      case LocationKind.home:
        return Icons.home_outlined;
      case LocationKind.work:
        return Icons.work_outline;
      case LocationKind.other:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final locationsAsync = ref.watch(savedLocationsProvider);
    final isEditing = widget.isEditing;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit Routine Block' : 'Add Routine Block',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'University',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Location',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a saved place from My Places.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            locationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load saved places.'),
              data: (locations) {
                _prefillLocation(locations);

                if (locations.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'No saved places yet — add one in the Places tab.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go(RoutePaths.locations);
                            },
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Go to My Places'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: locations.map((location) {
                    final selected = _selectedLocation?.id == location.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: selected
                          ? AppColors.primaryTeal.withValues(alpha: 0.12)
                          : null,
                      child: ListTile(
                        leading: Icon(_iconFor(location.kind)),
                        title: Text(location.name),
                        subtitle: Text(
                          location.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryTeal,
                              )
                            : null,
                        onTap: () =>
                            setState(() => _selectedLocation = location),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_startTime.format(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_endTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Days',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            if (!isEditing)
              Text(
                'Today (${_dayLabels[weekdayIndex(DateTime.now())]}) is pre-selected.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final selected = _selectedDays.contains(index);
                return FilterChip(
                  label: Text(_dayLabels[index]),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedDays.add(index);
                      } else {
                        _selectedDays.remove(index);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: RoutineBlockColors.presets.map((color) {
                final selected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: locationsAsync.maybeWhen(
                data: (locations) => locations.isEmpty ? null : _submit,
                orElse: () => null,
              ),
              child: Text(isEditing ? 'Save Changes' : 'Save Block'),
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                label: const Text(
                  'Delete Block',
                  style: TextStyle(color: AppColors.errorRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
