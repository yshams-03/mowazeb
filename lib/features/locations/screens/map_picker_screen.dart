import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../models/map_picker_result.dart';
import '../services/reverse_geocode_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLatLng,
    this.reverseGeocodeService,
  });

  final LatLng? initialLatLng;
  final ReverseGeocodeService? reverseGeocodeService;

  static const fallbackCenter = LatLng(30.0444, 31.2357);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _pinLiftPx = 8.0;
  static const _debounceMs = 600;
  static const _defaultZoom = 15.0;

  late LatLng _centerLatLng;
  late final MapController _mapController;
  bool _isMoving = false;
  bool _isGeocoding = false;
  MapPickerResult? _address;
  Timer? _debounceTimer;
  LatLng? _userGpsLatLng;

  late final ReverseGeocodeService _geocodeService;

  @override
  void initState() {
    super.initState();
    _geocodeService =
        widget.reverseGeocodeService ?? ReverseGeocodeService();
    _centerLatLng = widget.initialLatLng ?? MapPickerScreen.fallbackCenter;
    _mapController = MapController();
    _resolveInitialCamera();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialCamera() async {
    LatLng? target = widget.initialLatLng;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        target = LatLng(position.latitude, position.longitude);
        _userGpsLatLng = target;
      }
    } catch (_) {
      // GPS unavailable — keep settings fallback or Cairo default.
    }

    if (!mounted) return;

    setState(() {
      _centerLatLng = target ?? MapPickerScreen.fallbackCenter;
      if (_userGpsLatLng == null &&
          widget.initialLatLng != null &&
          target == widget.initialLatLng) {
        _userGpsLatLng = widget.initialLatLng;
      }
    });

    _mapController.move(_centerLatLng, _defaultZoom);
    await _reverseGeocode(_centerLatLng);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart || event is MapEventMove) {
      _debounceTimer?.cancel();
      if (mounted) {
        setState(() {
          _centerLatLng = _mapController.camera.center;
          _isMoving = true;
        });
      }
    }

    if (event is MapEventMoveEnd) {
      if (mounted) {
        setState(() {
          _centerLatLng = _mapController.camera.center;
          _isMoving = false;
        });
      }
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: _debounceMs),
        () => _reverseGeocode(_centerLatLng),
      );
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _isGeocoding = true;
      _address = null;
    });

    final result = await _geocodeService.reverseGeocode(
      latLng.latitude,
      latLng.longitude,
    );

    if (!mounted) return;

    setState(() => _isGeocoding = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't get address. Try moving the map slightly."),
        ),
      );
      return;
    }

    setState(() => _address = result);
  }

  void _confirmSelection() {
    if (_address == null || _isGeocoding) return;
    Navigator.of(context).pop(_address);
  }

  Future<void> _goToMyLocation() async {
    LatLng? target = _userGpsLatLng;

    if (target == null) {
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission needed. Grant it in Settings.',
                ),
              ),
            );
          }
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        target = LatLng(position.latitude, position.longitude);
        _userGpsLatLng = target;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission needed. Grant it in Settings.',
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _centerLatLng = target!);
    _mapController.move(target, 16);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLatLng,
              initialZoom: _defaultZoom,
              onMapEvent: _onMapEvent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ummahpulse.ummah_pulse',
              ),
              if (_userGpsLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userGpsLatLng!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  0,
                  _isMoving ? -_pinLiftPx : 0,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.85),
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      BackButton(
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                      Expanded(
                        child: Text(
                          'Pick a location',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildAddressContent(theme),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _address != null && !_isGeocoding
                            ? _confirmSelection
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          disabledBackgroundColor: Colors.grey.shade400,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'map_my_location',
              backgroundColor: surfaceColor,
              foregroundColor: AppColors.primaryTeal,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressContent(ThemeData theme) {
    if (_isMoving || _isGeocoding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 160,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }

    if (_address != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _address!.shortName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _address!.address,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      'Move the map to select a location',
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
    );
  }
}
