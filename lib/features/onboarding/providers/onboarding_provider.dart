import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_settings.dart';
import '../../../features/prayer/services/location_label_service.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.latitude,
    this.longitude,
    this.calculationMethod = CalculationMethods.mwl,
    this.madhab = MadhabOptions.standard,
    this.locationGranted = false,
    this.locationLabel,
    this.isSaving = false,
    this.error,
  });

  final int currentStep;
  final double? latitude;
  final double? longitude;
  final String calculationMethod;
  final String madhab;
  final bool locationGranted;
  final String? locationLabel;
  final bool isSaving;
  final String? error;

  bool get canProceedFromLocation => locationGranted && latitude != null;

  OnboardingState copyWith({
    int? currentStep,
    double? latitude,
    double? longitude,
    String? calculationMethod,
    String? madhab,
    bool? locationGranted,
    String? locationLabel,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      locationGranted: locationGranted ?? this.locationGranted,
      locationLabel: locationLabel ?? this.locationLabel,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._firestore, this._auth) : super(const OnboardingState());

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> requestLocation() async {
    state = state.copyWith(clearError: true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        error: 'Location services are disabled. Please enable them in settings.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      final handlerStatus = await Permission.location.request();
      if (handlerStatus.isDenied) {
        state = state.copyWith(
          error: 'Location permission is required for accurate prayer times.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        error: 'Location permission permanently denied. Enable it in app settings.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final label = await resolveLocationLabel(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: label,
        locationGranted: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Could not get your location. Please try again.',
      );
    }
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void setCalculationMethod(String method) {
    if (state.calculationMethod == method) return;
    state = state.copyWith(calculationMethod: method);
  }

  void setMadhab(String madhab) {
    if (state.madhab == madhab) return;
    state = state.copyWith(madhab: madhab);
  }

  Future<bool> completeOnboarding() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final settings = UserSettings(
        onboardingComplete: true,
        calculationMethod: state.calculationMethod,
        madhab: state.madhab,
        latitude: state.latitude,
        longitude: state.longitude,
        locationLabel: state.locationLabel,
      );

      await _firestore
          .doc(FirestorePaths.userSettings(user.uid))
          .set(settings.toFirestore(), SetOptions(merge: true));

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save preferences. Please try again.',
      );
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});
