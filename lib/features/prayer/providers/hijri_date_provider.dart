import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hijri_date_info.dart';
import '../services/aladhan_sync_service.dart';

final hijriDateProvider = FutureProvider<HijriDateInfo>((ref) {
  return AlAdhanSyncService.getHijriDate();
});
