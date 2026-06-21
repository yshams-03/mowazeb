// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'mowazeb';

  @override
  String get tagline => 'Never miss a prayer';

  @override
  String get navHome => 'Home';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navPlaces => 'Places';

  @override
  String get navCommute => 'Commute';

  @override
  String get navCommunity => 'Community';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get allPrayersComplete => 'All Prayers Complete';

  @override
  String get remaining => 'remaining';

  @override
  String get seeYouAtFajr => 'See you at Fajr tomorrow';

  @override
  String get refreshPrayerTimes => 'Refresh prayer times';

  @override
  String get retry => 'Retry';

  @override
  String get now => 'Now';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get qibla => 'Qibla';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° from North';
  }

  @override
  String distanceToMecca(String distance) {
    return '$distance km to Mecca';
  }

  @override
  String get openQiblaCompass => 'Open Qibla Compass';

  @override
  String get locationRequired =>
      'Location permission is required for Qibla direction.';

  @override
  String get sensorNotSupported =>
      'Compass sensor not available on this device.';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get prayerCalculation => 'Prayer calculation';

  @override
  String get calculationMethod => 'Calculation method';

  @override
  String get madhabAsr => 'Madhab for Asr';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get homeAddress => 'Home address';

  @override
  String get homeAddressHint => 'Used for Smart Commute Advisor';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationPrayers => 'Prayer alerts';

  @override
  String get ramadanMode => 'Ramadan mode';

  @override
  String get ramadanAuto => 'Auto-detect';

  @override
  String get ramadanOn => 'Always on';

  @override
  String get ramadanOff => 'Off';

  @override
  String get arabicNumerals => 'Arabic numerals';

  @override
  String get arabicNumeralsSubtitle => 'Display ٠١٢٣ instead of 0123';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'This permanently deletes your account and data. Continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get ramadanMubarak => 'Ramadan Mubarak 🌙';

  @override
  String get iftarCountdown => 'Iftar in';

  @override
  String get suhoor => 'Suhoor';

  @override
  String get iftar => 'Iftar';

  @override
  String get privateAnalytics =>
      'Private to you — never shared with circle members';

  @override
  String get analytics => 'Analytics';

  @override
  String get badges => 'Badges';

  @override
  String personalBest(int days) {
    return 'Personal best: $days days';
  }

  @override
  String dayStreak(int count) {
    return '$count day streak';
  }

  @override
  String get login => 'Log in';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get goHome => 'Go Home';

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }
}
