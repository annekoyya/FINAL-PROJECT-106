import 'letter_status.dart';

/// The evaluated result of one guessed word: each letter paired with its status.
class GuessResult {
  final String word;
  final List<LetterStatus> statuses;

  GuessResult({required this.word, required this.statuses});

  bool get isWin => statuses.every((s) => s == LetterStatus.correct);

  Map<String, dynamic> toJson() => {
        'word': word,
        'statuses': statuses.map((s) => s.name).toList(),
      };

  factory GuessResult.fromJson(Map<String, dynamic> json) => GuessResult(
        word: json['word'] as String,
        statuses: (json['statuses'] as List)
            .map((s) => LetterStatus.values.byName(s as String))
            .toList(),
      );
}
