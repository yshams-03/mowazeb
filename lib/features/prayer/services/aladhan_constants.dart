import '../../../core/constants/app_constants.dart';

/// AlAdhan REST API constants — used only for daily background sync, never
/// for on-screen prayer time display (that uses the local [adhan] package).
class AlAdhanConstants {
  AlAdhanConstants._();

  static const baseUrl = 'https://api.aladhan.com/v1';

  /// Maps app calculation method labels to AlAdhan method IDs.
  static const methodIds = <String, int>{
    CalculationMethods.mwl: 3,
    CalculationMethods.isna: 2,
    CalculationMethods.egyptian: 5,
    CalculationMethods.ummAlQura: 4,
    CalculationMethods.karachi: 1,
  };

  static int methodIdFor(String? method) {
    return methodIds[method ?? CalculationMethods.mwl] ?? 3;
  }

  static int schoolFor(String? madhab) {
    return madhab == MadhabOptions.hanafi ? 1 : 0;
  }

  /// Unix timestamp for start of local calendar day (AlAdhan `/timings/{timestamp}`).
  static int unixTimestampForDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.millisecondsSinceEpoch ~/ 1000;
  }

  /// Converts `YYYY-MM-DD` to AlAdhan's `DD-MM-YYYY` path segment (legacy).
  static String dateParam(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }
}
