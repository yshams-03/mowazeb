/// Resolves the device IANA timezone and offset for server-side scheduling.
class DeviceTimezone {
  DeviceTimezone._();

  /// Best-effort IANA name; may be a Windows name on some platforms.
  static String get name => DateTime.now().timeZoneName;

  static int get offsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  static Map<String, dynamic> toFirestoreFields() {
    return {
      'timezone': name,
      'timezoneOffsetMinutes': offsetMinutes,
    };
  }
}
