import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/location_suggestion.dart';
import '../models/map_picker_result.dart';
import '../models/saved_location.dart';
import '../providers/locations_provider.dart';
import '../screens/map_picker_screen.dart';
import '../services/location_search_service.dart';

class AddPlaceSheet extends ConsumerStatefulWidget {
  const AddPlaceSheet({
    super.key,
    this.initialMapResult,
    this.existingLocation,
  });

  final MapPickerResult? initialMapResult;
  final SavedLocation? existingLocation;

  bool get isEditing => existingLocation != null;

  static Future<void> show(
    BuildContext context, {
    MapPickerResult? initialMapResult,
    SavedLocation? existingLocation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddPlaceSheet(
        initialMapResult: initialMapResult,
        existingLocation: existingLocation,
      ),
    );
  }

  @override
  ConsumerState<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<AddPlaceSheet> {
  final _searchController = TextEditingController();
  final _labelController = TextEditingController();
  final _labelFocus = FocusNode();
  final _searchFocus = FocusNode();

  LocationSuggestion? _selected;
  LocationKind _kind = LocationKind.other;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _changingLocation = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final existing = widget.existingLocation;
    if (existing != null) {
      _loadExisting(existing);
    } else {
      final initial = widget.initialMapResult;
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyMapResult(initial);
        });
      }
    }
  }

  void _loadExisting(SavedLocation location) {
    _selected = LocationSuggestion(
      displayName: location.address,
      shortName: location.name,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    _labelController.text = location.name;
    _kind = location.kind;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _labelController.dispose();
    _labelFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_selected != null) {
      final current = _searchController.text.trim();
      if (current != _selected!.shortName && current != _selected!.address) {
        setState(() => _selected = null);
      }
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _searchError = null;
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final settings = ref.read(userSettingsProvider).valueOrNull;
    final searchService = ref.read(locationSearchServiceProvider);
    final nearCity = settings?.locationLabel?.split(',').first.trim();

    try {
      final results = await searchService.search(
        query,
        biasLat: settings?.latitude,
        biasLng: settings?.longitude,
        nearCity: nearCity,
      );

      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
        _searchError =
            results.isEmpty ? 'No places found. Try a different search.' : null;
      });
    } on LocationSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _searchError = e.message;
      });
    }
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    _debounce?.cancel();
    setState(() {
      _selected = suggestion;
      _suggestions = [];
      _searchError = null;
      _changingLocation = false;
      _searchController.text = suggestion.shortName;
      if (!widget.isEditing) {
        _labelController.text = suggestion.shortName;
        if (suggestion.shortName.toLowerCase().contains('home')) {
          _kind = LocationKind.home;
        } else {
          _kind = LocationKind.other;
        }
      }
    });

    FocusScope.of(context).unfocus();
    Future.microtask(() => _labelFocus.requestFocus());
  }

  void _applyMapResult(MapPickerResult result) {
    _debounce?.cancel();
    setState(() {
      _selected = result.toLocationSuggestion();
      _suggestions = [];
      _searchError = null;
      _changingLocation = false;
      _searchController.clear();
      if (!widget.isEditing) {
        _labelController.text = result.shortName;
      }
      if (!widget.isEditing &&
          result.shortName.toLowerCase().contains('home')) {
        _kind = LocationKind.home;
      } else if (!widget.isEditing) {
        _kind = LocationKind.other;
      }
    });
    Future.microtask(() => _labelFocus.requestFocus());
  }

  Future<void> _pickOnMap() async {
    LatLng? initial;
    if (_selected != null) {
      initial = LatLng(_selected!.latitude, _selected!.longitude);
    } else {
      final settings = ref.read(userSettingsProvider).valueOrNull;
      if (settings?.latitude != null && settings?.longitude != null) {
        initial = LatLng(settings!.latitude!, settings.longitude!);
      }
    }

    final result = await Navigator.of(context, rootNavigator: true)
        .push<MapPickerResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPickerScreen(initialLatLng: initial),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      _searchFocus.requestFocus();
      return;
    }

    _applyMapResult(result);
  }

  void _focusSearchByName() {
    _searchFocus.requestFocus();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final selected = _selected;

    if (selected == null || label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a place from search results and give it a name.'),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final actions = ref.read(locationActionsProvider);
      if (widget.isEditing) {
        await actions.updateLocation(
          id: widget.existingLocation!.id,
          name: label,
          address: selected.address,
          latitude: selected.latitude,
          longitude: selected.longitude,
          kind: _kind,
        );
      } else {
        await actions.addLocation(
          name: label,
          address: selected.address,
          latitude: selected.latitude,
          longitude: selected.longitude,
          kind: _kind,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save place. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSave =
        _selected != null && _labelController.text.trim().isNotEmpty;
    final isEditing = widget.isEditing;
    final showLocationPicker =
        !isEditing || _changingLocation || _selected == null;
    final showSearchSection = showLocationPicker && _selected == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit Place' : 'Add Place',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (showLocationPicker) ...[
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Update location' : 'How do you want to find this place?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickOnMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pick on Map'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _focusSearchByName,
                      icon: const Icon(Icons.search),
                      label: const Text('Search by Name'),
                    ),
                  ),
                ],
              ),
            ],
            if (showSearchSection) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).hintColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).hintColor)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Search for a place',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _searchError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(
                          suggestion.shortName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          suggestion.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ],
            ],
            if (_selected != null) ...[
              const SizedBox(height: 12),
              Card(
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: AppColors.primaryTeal,
                  ),
                  title: Text(
                    _selected!.shortName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _selected!.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isEditing && !_changingLocation
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selected = null;
                              _searchController.clear();
                              _labelController.clear();
                              _suggestions = [];
                              _changingLocation = false;
                            });
                          },
                        ),
                ),
              ),
              if (isEditing && !_changingLocation) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _changingLocation = true),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Change location'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Label for this place',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                focusNode: _labelFocus,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'e.g. University, Gym, Office...',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: LocationKind.values.map((kind) {
                  final selected = _kind == kind;
                  return ChoiceChip(
                    label: Text(kind.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _kind = kind),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canSave && !_isSearching ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSearching && _selected != null
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Save Place'),
            ),
          ],
        ),
      ),
    );
  }
}
