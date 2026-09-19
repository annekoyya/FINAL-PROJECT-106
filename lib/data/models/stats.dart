class Stats {
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;
  final List<int> guessDistribution; // index 0..5 = wins in 1..6 guesses

  Stats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    List<int>? guessDistribution,
  }) : guessDistribution = guessDistribution ?? List.filled(6, 0);

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'guessDistribution': guessDistribution,
      };

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        gamesPlayed: json['gamesPlayed'] ?? 0,
        gamesWon: json['gamesWon'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        maxStreak: json['maxStreak'] ?? 0,
        guessDistribution: json['guessDistribution'] != null
            ? List<int>.from(json['guessDistribution'])
            : List.filled(6, 0),
      );
}
