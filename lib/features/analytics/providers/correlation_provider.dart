import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_models.dart';
import 'analytics_provider.dart';

/// Schedule correlation insights derived from prayer logs + routine blocks.
final correlationProvider = Provider<AsyncValue<List<ScheduleInsight>>>((ref) {
  return ref.watch(correlationInsightsProvider);
});
