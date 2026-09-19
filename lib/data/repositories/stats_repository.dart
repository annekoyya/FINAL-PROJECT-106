import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats.dart';

class StatsRepository {
  static const _key = 'player_stats';

  Future<Stats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return Stats();
    return Stats.fromJson(jsonDecode(raw));
  }

  Future<void> save(Stats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stats.toJson()));
  }
}
