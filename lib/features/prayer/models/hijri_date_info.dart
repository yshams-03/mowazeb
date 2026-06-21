import 'package:hijri/hijri_calendar.dart';

/// Hijri calendar fields from AlAdhan sync cache or offline fallback.
class HijriDateInfo {
  const HijriDateInfo({
    required this.day,
    required this.monthNum,
    required this.monthEn,
    required this.monthAr,
    required this.year,
  });

  final int day;
  final int monthNum;
  final String monthEn;
  final String monthAr;
  final int year;

  factory HijriDateInfo.fromAlAdhanJson(Map<String, dynamic> hijri) {
    final month = hijri['month'] as Map<String, dynamic>? ?? {};
    final dayRaw = hijri['day'];
    final yearRaw = hijri['year'];
    final monthNumRaw = month['number'];

    return HijriDateInfo(
      day: int.tryParse('$dayRaw') ?? 1,
      monthNum: monthNumRaw is int
          ? monthNumRaw
          : int.tryParse('$monthNumRaw') ?? 1,
      monthEn: (month['en'] as String?) ?? '',
      monthAr: (month['ar'] as String?) ?? (month['en'] as String?) ?? '',
      year: int.tryParse('$yearRaw') ?? HijriCalendar.now().hYear,
    );
  }

  factory HijriDateInfo.fromHijriPackage([DateTime? date]) {
    final h = HijriCalendar.fromDate(date ?? DateTime.now());
    return HijriDateInfo(
      day: h.hDay,
      monthNum: h.hMonth,
      monthEn: h.longMonthName,
      monthAr: h.longMonthName,
      year: h.hYear,
    );
  }

  factory HijriDateInfo.fromPrefs(Map<String, dynamic> map) {
    return HijriDateInfo(
      day: map['day'] as int? ?? 1,
      monthNum: map['monthNum'] as int? ?? 1,
      monthEn: map['monthEn'] as String? ?? '',
      monthAr: map['monthAr'] as String? ?? '',
      year: map['year'] as int? ?? 1440,
    );
  }

  Map<String, dynamic> toPrefs() => {
        'day': day,
        'monthNum': monthNum,
        'monthEn': monthEn,
        'monthAr': monthAr,
        'year': year,
      };

  String formatEnglish() {
    if (monthEn.isEmpty) return '$day $year';
    return '$day $monthEn $year';
  }

  String formatArabic({required bool arabicNumerals}) {
    final d = arabicNumerals ? _toEastern(day) : '$day';
    final y = arabicNumerals ? _toEastern(year) : '$year';
    final month = monthAr.isNotEmpty ? monthAr : monthEn;
    return '$d $month $y';
  }

  static String _toEastern(int value) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().replaceAllMapped(
          RegExp(r'\d'),
          (m) => digits[int.parse(m.group(0)!)],
        );
  }
}
