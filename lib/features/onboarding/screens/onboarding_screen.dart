import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pinController;
  late Animation<double> _pinBounce;
  late Animation<double> _pinFade;

  @override
  void initState() {
    super.initState();
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pinBounce = Tween<double>(begin: 0, end: -16).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeInOut),
    );
    _pinFade = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        leading: onboarding.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(currentStep: onboarding.currentStep),
              const SizedBox(height: 32),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(context, onboarding),
                ),
              ),
              if (onboarding.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          onboarding.error!,
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildActionButton(context, onboarding, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingState state) {
    switch (state.currentStep) {
      case 0:
        return _LocationStep(
          key: const ValueKey(0),
          pinBounce: _pinBounce,
          pinFade: _pinFade,
          locationGranted: state.locationGranted,
          latitude: state.latitude,
          longitude: state.longitude,
        );
      case 1:
        return _CalculationMethodStep(
          key: const ValueKey(1),
          selected: state.calculationMethod,
          onSelected: ref.read(onboardingControllerProvider.notifier).setCalculationMethod,
        );
      case 2:
        return _MadhabStep(
          key: const ValueKey(2),
          selected: state.madhab,
          onSelected: ref.read(onboardingControllerProvider.notifier).setMadhab,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    OnboardingState state,
    OnboardingController controller,
  ) {
    if (state.currentStep == 0) {
      if (!state.locationGranted) {
        return ElevatedButton.icon(
          onPressed: controller.requestLocation,
          icon: const Icon(Icons.location_on),
          label: const Text('Enable Location'),
        );
      }
      return ElevatedButton(
        onPressed: state.canProceedFromLocation ? controller.nextStep : null,
        child: const Text('Continue'),
      );
    }

    if (state.currentStep == 1) {
      return ElevatedButton(
        onPressed: controller.nextStep,
        child: const Text('Continue'),
      );
    }

    return ElevatedButton(
      onPressed: state.isSaving
          ? null
          : () async {
              final success = await controller.completeOnboarding();
              if (success && context.mounted) {
                context.go(RoutePaths.home);
              }
            },
      child: state.isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Get Started'),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGreen
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    super.key,
    required this.pinBounce,
    required this.pinFade,
    required this.locationGranted,
    this.latitude,
    this.longitude,
  });

  final Animation<double> pinBounce;
  final Animation<double> pinFade;
  final bool locationGranted;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: pinBounce,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, pinBounce.value),
              child: Opacity(
                opacity: pinFade.value,
                child: Icon(
                  locationGranted ? Icons.location_on : Icons.location_searching,
                  size: 96,
                  color: AppColors.primaryGreen,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Find Your Location',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          locationGranted
              ? 'Location detected! Prayer times will be calculated for your area.'
              : 'We need your location to calculate accurate prayer times for where you are.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
        if (locationGranted && latitude != null && longitude != null) ...[
          const SizedBox(height: 16),
          Text(
            '${latitude!.toStringAsFixed(4)}°, ${longitude!.toStringAsFixed(4)}°',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryTeal,
                ),
          ),
        ],
      ],
    );
  }
}

class _CalculationMethodStep extends StatelessWidget {
  const _CalculationMethodStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Method',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the method used to calculate prayer times in your region.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: CalculationMethods.all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final method = CalculationMethods.all[index];
              final isSelected = method == selected;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  title: Text(method),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                      : null,
                  onTap: () => onSelected(method),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MadhabStep extends StatelessWidget {
  const _MadhabStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asr Calculation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your madhab for Asr prayer time calculation.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ...MadhabOptions.all.map((madhab) {
          final isSelected = madhab == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                title: Text(madhab),
                subtitle: Text(
                  madhab == MadhabOptions.hanafi
                      ? 'Later Asr time (Hanafi school)'
                      : 'Standard Shafi\'i, Maliki, Hanbali',
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                    : null,
                onTap: () => onSelected(madhab),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }
}
