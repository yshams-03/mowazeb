import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakCacheService {
  StreakCacheService(this._prefs);

  final SharedPreferences _prefs;

  static const _currentKey = 'streak_current';
  static const _longestKey = 'streak_longest';

  int get cachedCurrent => _prefs.getInt(_currentKey) ?? 0;
  int get cachedLongest => _prefs.getInt(_longestKey) ?? 0;

  Future<void> cache({required int current, required int longest}) async {
    await _prefs.setInt(_currentKey, current);
    await _prefs.setInt(_longestKey, longest);
  }
}

final streakCacheServiceProvider = FutureProvider<StreakCacheService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return StreakCacheService(prefs);
});
