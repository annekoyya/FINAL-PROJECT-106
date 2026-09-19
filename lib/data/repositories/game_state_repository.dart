import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guess_result.dart';

class GameStateRepository {
  /// Loads the saved game state for a specific date (e.g., '2024-10-25').
  /// Returns null if no game has been started/saved for that date.
  Future<Map<String, dynamic>?> load(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('game_state_$dateKey');
    if (raw == null) return null;
    
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Saves the current guesses and game status for a specific date.
  Future<void> save({
    required String dateKey,
    required List<GuessResult> guesses,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final data = {
      'guesses': guesses.map((g) => g.toJson()).toList(),
      'status': status,
    };
    
    await prefs.setString('game_state_$dateKey', jsonEncode(data));
  }
}