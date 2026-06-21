const _easternArabicDigits = '٠١٢٣٤٥٦٧٨٩';

class AppFormat {
  AppFormat._();

  static String localizeDigits(String input, {required bool arabicNumerals}) {
    if (!arabicNumerals) return input;
    return input.replaceAllMapped(
      RegExp(r'\d'),
      (match) => _easternArabicDigits[int.parse(match.group(0)!)],
    );
  }

  static String number(num value, {required bool arabicNumerals}) {
    return localizeDigits(value.toString(), arabicNumerals: arabicNumerals);
  }

  static String duration(Duration duration, {required bool arabicNumerals}) {
    if (duration <= Duration.zero) {
      return localizeDigits('Now', arabicNumerals: false);
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return localizeDigits(
        '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s',
        arabicNumerals: arabicNumerals,
      );
    }
    if (minutes > 0) {
      return localizeDigits(
        '${minutes}m ${seconds.toString().padLeft(2, '0')}s',
        arabicNumerals: arabicNumerals,
      );
    }
    return localizeDigits('${seconds}s', arabicNumerals: arabicNumerals);
  }
}
