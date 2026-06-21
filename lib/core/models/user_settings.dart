class UserSettings {
  const UserSettings({
    this.onboardingComplete = false,
    this.calculationMethod,
    this.madhab,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.homeAddress,
    this.circleIds = const [],
    this.dayStatus,
    this.themeMode,
    this.locale,
    this.arabicNumerals,
    this.ramadanModeOverride,
    this.notificationPrayers = const [
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    ],
    this.timezone,
  });

  final bool onboardingComplete;
  final String? calculationMethod;
  final String? madhab;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final String? homeAddress;
  final List<String> circleIds;
  final String? dayStatus;
  final String? themeMode;
  final String? locale;
  final bool? arabicNumerals;
  final String? ramadanModeOverride;
  final List<String> notificationPrayers;
  final String? timezone;

  bool get isComplete =>
      onboardingComplete &&
      calculationMethod != null &&
      madhab != null &&
      latitude != null &&
      longitude != null;

  factory UserSettings.fromFirestore(Map<String, dynamic>? data) =>
      UserSettings.fromMap(data);

  factory UserSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const UserSettings();
    return UserSettings(
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      calculationMethod: data['calculationMethod'] as String?,
      madhab: data['madhab'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationLabel: data['locationLabel'] as String?,
      homeAddress: data['homeAddress'] as String?,
      circleIds: List<String>.from(data['circleIds'] as List? ?? const []),
      dayStatus: data['dayStatus'] as String?,
      themeMode: data['themeMode'] as String?,
      locale: data['locale'] as String?,
      arabicNumerals: data['arabicNumerals'] as bool?,
      ramadanModeOverride: data['ramadanModeOverride'] as String?,
      notificationPrayers: List<String>.from(
        data['notificationPrayers'] as List? ??
            const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
      ),
      timezone: data['timezone'] as String?,
    );
  }

  Map<String, dynamic> toMap() => toFirestore();

  Map<String, dynamic> toFirestore() {
    return {
      'onboardingComplete': onboardingComplete,
      if (calculationMethod != null) 'calculationMethod': calculationMethod,
      if (madhab != null) 'madhab': madhab,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationLabel != null) 'locationLabel': locationLabel,
      if (homeAddress != null) 'homeAddress': homeAddress,
      if (circleIds.isNotEmpty) 'circleIds': circleIds,
      if (dayStatus != null) 'dayStatus': dayStatus,
      if (themeMode != null) 'themeMode': themeMode,
      if (locale != null) 'locale': locale,
      if (arabicNumerals != null) 'arabicNumerals': arabicNumerals,
      if (ramadanModeOverride != null) 'ramadanModeOverride': ramadanModeOverride,
      'notificationPrayers': notificationPrayers,
      if (timezone != null) 'timezone': timezone,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserSettings copyWith({
    bool? onboardingComplete,
    String? calculationMethod,
    String? madhab,
    double? latitude,
    double? longitude,
    String? locationLabel,
    String? homeAddress,
    List<String>? circleIds,
    String? dayStatus,
    String? themeMode,
    String? locale,
    bool? arabicNumerals,
    String? ramadanModeOverride,
    List<String>? notificationPrayers,
    String? timezone,
  }) {
    return UserSettings(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      homeAddress: homeAddress ?? this.homeAddress,
      circleIds: circleIds ?? this.circleIds,
      dayStatus: dayStatus ?? this.dayStatus,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      arabicNumerals: arabicNumerals ?? this.arabicNumerals,
      ramadanModeOverride: ramadanModeOverride ?? this.ramadanModeOverride,
      notificationPrayers: notificationPrayers ?? this.notificationPrayers,
      timezone: timezone ?? this.timezone,
    );
  }
}
