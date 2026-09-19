class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.unlocked = false,
  });

  Achievement copyWith({bool? unlocked}) => Achievement(
        id: id,
        title: title,
        description: description,
        unlocked: unlocked ?? this.unlocked,
      );
}

/// The master list of achievements the game can unlock.
const List<Achievement> kAllAchievements = [
  Achievement(id: 'first_win', title: 'First Blood', description: 'Win your first game.'),
  Achievement(id: 'one_guess', title: 'Lucky Guess', description: 'Win in a single guess.'),
  Achievement(id: 'streak_3', title: 'On a Roll', description: 'Reach a 3-day streak.'),
  Achievement(id: 'streak_7', title: 'Week Warrior', description: 'Reach a 7-day streak.'),
  Achievement(id: 'no_yellow', title: 'Clean Sweep', description: 'Win with no yellow tiles.'),
  Achievement(id: 'ten_games', title: 'Regular', description: 'Play 10 games.'),
];
