// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مواظب';

  @override
  String get tagline => 'لا تفوت صلاة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navPlanner => 'المخطط';

  @override
  String get navPlaces => 'الأماكن';

  @override
  String get navCommute => 'التنقل';

  @override
  String get navCommunity => 'المجتمع';

  @override
  String get navAnalytics => 'التحليلات';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get allPrayersComplete => 'اكتملت جميع الصلوات';

  @override
  String get remaining => 'متبقية';

  @override
  String get seeYouAtFajr => 'نراك في الفجر غداً';

  @override
  String get refreshPrayerTimes => 'تحديث أوقات الصلاة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get now => 'الآن';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get qibla => 'القبلة';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° من الشمال';
  }

  @override
  String distanceToMecca(String distance) {
    return '$distance كم إلى مكة';
  }

  @override
  String get openQiblaCompass => 'فتح بوصلة القبلة';

  @override
  String get locationRequired => 'مطلوب إذن الموقع لاتجاه القبلة.';

  @override
  String get sensorNotSupported => 'مستشعر البوصلة غير متوفر على هذا الجهاز.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get prayerCalculation => 'حساب الصلاة';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get madhabAsr => 'المذهب للعصر';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get homeAddress => 'عنوان المنزل';

  @override
  String get homeAddressHint => 'يُستخدم في مستشار التنقل الذكي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationPrayers => 'تنبيهات الصلاة';

  @override
  String get ramadanMode => 'وضع رمضان';

  @override
  String get ramadanAuto => 'كشف تلقائي';

  @override
  String get ramadanOn => 'تشغيل دائم';

  @override
  String get ramadanOff => 'إيقاف';

  @override
  String get arabicNumerals => 'الأرقام العربية';

  @override
  String get arabicNumeralsSubtitle => 'عرض ٠١٢٣ بدلاً من 0123';

  @override
  String get account => 'الحساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirm =>
      'سيؤدي هذا إلى حذف حسابك وبياناتك نهائياً. هل تريد المتابعة؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get ramadanMubarak => 'رمضان مبارك 🌙';

  @override
  String get iftarCountdown => 'الإفطار بعد';

  @override
  String get suhoor => 'السحور';

  @override
  String get iftar => 'الإفطار';

  @override
  String get privateAnalytics => 'خاص بك — لا يُشارك مع أعضاء الدائرة';

  @override
  String get analytics => 'التحليلات';

  @override
  String get badges => 'الشارات';

  @override
  String personalBest(int days) {
    return 'أفضل إنجاز: $days أيام';
  }

  @override
  String dayStreak(int count) {
    return 'سلسلة $count أيام';
  }

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بـ Google';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String pageNotFound(String uri) {
    return 'الصفحة غير موجودة: $uri';
  }
}
