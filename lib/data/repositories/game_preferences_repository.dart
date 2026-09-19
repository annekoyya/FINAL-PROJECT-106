import 'package:shared_preferences/shared_preferences.dart';

enum DuelInvitePolicy { everyone, friendsOnly, noOne }

/// Persists the Profile screen's "Game Preferences" toggles, matching the
/// Wordie mockups: Tile Theme, High-Contrast Tiles, Haptics & Feedback,
/// and Duel Invites policy.
class GamePreferencesRepository {
  static const _highContrastKey = 'pref_high_contrast_tiles';
  static const _hapticsKey = 'pref_haptics_enabled';
  static const _duelInvitesKey = 'pref_duel_invites';

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'highContrast': prefs.getBool(_highContrastKey) ?? false,
      'haptics': prefs.getBool(_hapticsKey) ?? true,
      'duelInvites': prefs.getString(_duelInvitesKey) ?? DuelInvitePolicy.friendsOnly.name,
    };
  }

  Future<void> setHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  Future<void> setHaptics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  Future<void> setDuelInvitePolicy(DuelInvitePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_duelInvitesKey, policy.name);
  }
}