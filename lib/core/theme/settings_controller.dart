import 'package:flutter/foundation.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/game_preferences_repository.dart';
import 'app_colors.dart';

class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;
  final GamePreferencesRepository _preferencesRepository;

  bool isDarkMode = false;
  bool useHighContrastPalette = false; // "High-Contrast Tiles" in Profile
  bool hardMode = false;
  bool hapticsEnabled = true;          // "Haptics & Feedback" in Profile
  DuelInvitePolicy duelInvitePolicy = DuelInvitePolicy.friendsOnly;

  SettingsController(this._repository, [GamePreferencesRepository? preferencesRepository])
      : _preferencesRepository = preferencesRepository ?? GamePreferencesRepository();

  TileColors get tileColors => useHighContrastPalette ? TileColors.highContrast : TileColors.classic;

  Future<void> load() async {
    final values = await _repository.load();
    isDarkMode = values['darkMode']!;
    hardMode = values['hardMode']!;

    final prefs = await _preferencesRepository.load();
    useHighContrastPalette = prefs['highContrast'];
    hapticsEnabled = prefs['haptics'];
    duelInvitePolicy = DuelInvitePolicy.values.firstWhere(
      (p) => p.name == prefs['duelInvites'],
      orElse: () => DuelInvitePolicy.friendsOnly,
    );

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode = value;
    notifyListeners();
    await _repository.setDarkMode(value);
  }

  Future<void> toggleHighContrast(bool value) async {
    useHighContrastPalette = value;
    notifyListeners();
    await _preferencesRepository.setHighContrast(value);
  }

  Future<void> toggleHardMode(bool value) async {
    hardMode = value;
    notifyListeners();
    await _repository.setHardMode(value);
  }

  Future<void> toggleHaptics(bool value) async {
    hapticsEnabled = value;
    notifyListeners();
    await _preferencesRepository.setHaptics(value);
  }

  Future<void> setDuelInvitePolicy(DuelInvitePolicy policy) async {
    duelInvitePolicy = policy;
    notifyListeners();
    await _preferencesRepository.setDuelInvitePolicy(policy);
  }
}
