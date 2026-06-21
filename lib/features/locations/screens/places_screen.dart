import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../models/saved_location.dart';
import '../providers/locations_provider.dart';
import '../widgets/add_place_sheet.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  String _emojiFor(LocationKind kind) {
    switch (kind) {
      case LocationKind.home:
        return '🏠';
      case LocationKind.work:
        return '💼';
      case LocationKind.other:
        return '📍';
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedLocation location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text('Remove "${location.name}" from your saved places?'),
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

    if (confirmed == true) {
      await ref.read(locationActionsProvider).deleteLocation(location.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeLocationSeederProvider);
    final locationsAsync = ref.watch(savedLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Places'),
      ),
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load saved places.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (locations) {
          if (locations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 72,
                      color: AppColors.primaryTeal.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No saved places yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first place.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final location = locations[index];
              return Card(
                child: ListTile(
                  leading: Text(
                    _emojiFor(location.kind),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    location.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    location.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  onTap: () =>
                      AddPlaceSheet.show(context, existingLocation: location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => AddPlaceSheet.show(
                          context,
                          existingLocation: location,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDelete(context, ref, location),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddPlaceSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Place'),
      ),
    );
  }
}
