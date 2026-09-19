import '../models/letter_status.dart';
import '../models/guess_result.dart';

class GuessEvaluator {
  /// Evaluates [guess] against [answer], correctly handling duplicate letters.
  static GuessResult evaluate(String guess, String answer) {
    final guessLetters = guess.toUpperCase().split('');
    final answerLetters = answer.toUpperCase().split('');
    final statuses = List<LetterStatus>.filled(guessLetters.length, LetterStatus.absent);

    final remaining = <String, int>{};
    for (final letter in answerLetters) {
      remaining[letter] = (remaining[letter] ?? 0) + 1;
    }

    // Pass 1: exact position matches.
    for (var i = 0; i < guessLetters.length; i++) {
      if (guessLetters[i] == answerLetters[i]) {
        statuses[i] = LetterStatus.correct;
        remaining[guessLetters[i]] = remaining[guessLetters[i]]! - 1;
      }
    }

    // Pass 2: present / absent for everything else.
    for (var i = 0; i < guessLetters.length; i++) {
      if (statuses[i] == LetterStatus.correct) continue;
      final letter = guessLetters[i];
      if ((remaining[letter] ?? 0) > 0) {
        statuses[i] = LetterStatus.present;
        remaining[letter] = remaining[letter]! - 1;
      } else {
        statuses[i] = LetterStatus.absent;
      }
    }

    return GuessResult(word: guess.toUpperCase(), statuses: statuses);
  }
}
