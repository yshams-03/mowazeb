import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../planner/providers/ramadan_provider.dart';
import '../../../core/providers/app_preferences_provider.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isPreparing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isPreparing = true;
      _errorMessage = null;
    });

    try {
      if (Platform.isAndroid) {
        final sensorSupported = await FlutterQiblah.androidDeviceSensorSupport();
        if (sensorSupported == false) {
          if (!mounted) return;
          setState(() {
            _isPreparing = false;
            _errorMessage = l10n.sensorNotSupported;
          });
          return;
        }
      }

      var status = await FlutterQiblah.checkLocationStatus();
      if (!status.enabled) {
        if (!mounted) return;
        setState(() {
          _isPreparing = false;
          _errorMessage = l10n.locationRequired;
        });
        return;
      }

      if (status.status == LocationPermission.denied) {
        await FlutterQiblah.requestPermissions();
        status = await FlutterQiblah.checkLocationStatus();
      }

      if (status.status == LocationPermission.denied ||
          status.status == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isPreparing = false;
          _errorMessage = l10n.locationRequired;
        });
        return;
      }

      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      setState(() => _isPreparing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _errorMessage = l10n.sensorNotSupported;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final settings = ref.watch(userSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qiblaDirection)),
      body: _isPreparing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorState(
                  message: _errorMessage!,
                  onRetry: _prepare,
                )
              : StreamBuilder<QiblahDirection>(
                  stream: FlutterQiblah.qiblahStream.timeout(
                    const Duration(seconds: 15),
                    onTimeout: (sink) => sink.close(),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: l10n.sensorNotSupported,
                        onRetry: _prepare,
                      );
                    }

                    if (!snapshot.hasData) {
                      return _ErrorState(
                        message: l10n.sensorNotSupported,
                        onRetry: _prepare,
                      );
                    }

                    final direction = snapshot.data!;
                    final lat = settings?.latitude;
                    final lng = settings?.longitude;
                    final distanceKm = lat != null && lng != null
                        ? distanceToMeccaKm(lat, lng)
                        : null;

                    final degrees = AppFormat.number(
                      direction.offset.abs(),
                      arabicNumerals: prefs.arabicNumerals,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            l10n.degreesFromNorth(degrees),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (distanceKm != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.distanceToMecca(
                                AppFormat.number(
                                  distanceKm.round(),
                                  arabicNumerals: prefs.arabicNumerals,
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                          const Spacer(),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1 + (_pulseController.value * 0.04);
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: SizedBox(
                              height: 280,
                              width: 280,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: (direction.direction * (math.pi / 180) * -1),
                                    child: _CompassDial(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: (direction.qiblah * (math.pi / 180) * -1),
                                    child: const Icon(
                                      Icons.navigation,
                                      size: 120,
                                      color: AppColors.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'N',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 3),
        color: color.withValues(alpha: 0.06),
      ),
      child: CustomPaint(
        size: const Size(280, 280),
        painter: _CompassTicksPainter(color),
      ),
    );
  }
}

class _CompassTicksPainter extends CustomPainter {
  _CompassTicksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    for (var i = 0; i < 72; i++) {
      final angle = i * math.pi / 36;
      final inner = i % 9 == 0 ? radius - 16 : radius - 8;
      final start = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
