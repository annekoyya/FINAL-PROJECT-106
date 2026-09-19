import '../../../data/models/achievement.dart';
import '../../../data/models/guess_result.dart';
import '../../../data/models/letter_status.dart';
import '../../../data/models/stats.dart';

class AchievementChecker {
  /// Given the just-finished game and updated stats, returns the list of
  /// achievement IDs that should newly unlock (excluding ones already in
  /// [alreadyUnlocked]).
  static List<String> checkNewUnlocks({
    required bool won,
    required List<GuessResult> guesses,
    required Stats stats,
    required Set<String> alreadyUnlocked,
  }) {
    final newly = <String>[];

    void unlock(String id) {
      if (!alreadyUnlocked.contains(id) && !newly.contains(id)) {
        newly.add(id);
      }
    }

    if (won) {
      unlock('first_win');

      if (guesses.length == 1) {
        unlock('one_guess');
      }

      final lastGuess = guesses.last;
      final hasYellow = lastGuess.statuses.contains(LetterStatus.present) ||
          guesses.any((g) => g.statuses.contains(LetterStatus.present));
      if (!hasYellow) {
        unlock('no_yellow');
      }
    }

    if (stats.currentStreak >= 3) unlock('streak_3');
    if (stats.currentStreak >= 7) unlock('streak_7');
    if (stats.gamesPlayed >= 10) unlock('ten_games');

    return newly;
  }
}
