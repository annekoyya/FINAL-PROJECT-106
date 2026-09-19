import 'package:shared_preferences/shared_preferences.dart';

class AchievementsRepository {
  static const _key = 'unlocked_achievements';

  Future<Set<String>> loadUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    // Use getStringList instead of JSON decoding!
    final rawList = prefs.getStringList(_key);
    if (rawList == null) return {};
    return rawList.toSet();
  }

  Future<void> saveUnlockedIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // Use setStringList instead of JSON encoding!
    await prefs.setStringList(_key, ids.toList());
  }
}