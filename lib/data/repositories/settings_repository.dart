import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _darkModeKey = 'settings_dark_mode';
  static const _colorblindKey = 'settings_colorblind';
  static const _hardModeKey = 'settings_hard_mode';

  Future<Map<String, bool>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'darkMode': prefs.getBool(_darkModeKey) ?? true,
      'colorblind': prefs.getBool(_colorblindKey) ?? false,
      'hardMode': prefs.getBool(_hardModeKey) ?? false,
    };
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setColorblind(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorblindKey, value);
  }

  Future<void> setHardMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardModeKey, value);
  }
}
