import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../locations/models/saved_location.dart';
import '../../locations/providers/locations_provider.dart';
import '../../community/widgets/status_toggle.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _homeAddressController = TextEditingController();
  bool _isSaving = false;
  bool _didPrefill = false;

  @override
  void dispose() {
    _homeAddressController.dispose();
    super.dispose();
  }

  void _prefill(String? homeAddress, List<SavedLocation> locations) {
    if (_didPrefill) return;
    _didPrefill = true;

    for (final loc in locations) {
      if (loc.kind == LocationKind.home) {
        _homeAddressController.text = loc.name;
        return;
      }
    }

    if (homeAddress != null && homeAddress.trim().isNotEmpty) {
      _homeAddressController.text = homeAddress.trim();
      return;
    }

    final settings = ref.read(userSettingsProvider).valueOrNull;
    if (settings?.locationLabel != null) {
      _homeAddressController.text = settings!.locationLabel!;
    }
  }

  Future<void> _saveHomeAddress() async {
    final address = _homeAddressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a home address first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;

      final firestore = ref.read(firestoreProvider);
      await firestore.doc(FirestorePaths.userSettings(user.uid)).set(
        {'homeAddress': address},
        SetOptions(merge: true),
      );

      final locations = ref.read(savedLocationsProvider).valueOrNull ?? [];
      SavedLocation? home;
      for (final loc in locations) {
        if (loc.kind == LocationKind.home) {
          home = loc;
          break;
        }
      }

      if (home != null) {
        await ref.read(locationActionsProvider).updateLocation(
              id: home.id,
              name: address,
              address: home.address,
              latitude: home.latitude,
              longitude: home.longitude,
              kind: LocationKind.home,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Home address saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider).valueOrNull;
    final locationsAsync = ref.watch(savedLocationsProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    locationsAsync.whenData((locations) {
      _prefill(settings?.homeAddress, locations);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user?.email != null) ...[
            Text(
              user!.email!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
          ],
          const StatusToggle(),
          const SizedBox(height: 24),
          Text(
            'Home address',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Used as the default destination in Smart Commute Advisor.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _homeAddressController,
            decoration: const InputDecoration(
              hintText: 'e.g. 123 Main St, Cairo',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveHomeAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Home Address'),
            ),
          ),
        ],
      ),
    );
  }
}
