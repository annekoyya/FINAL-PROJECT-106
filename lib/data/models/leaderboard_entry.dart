class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int eloRating;
  final int streak;
  final int rank;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.eloRating,
    required this.streak,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(String uid, Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      uid: uid,
      displayName: json['displayName'] ?? 'Player',
      eloRating: json['eloRating'] ?? 1200,
      streak: json['currentStreak'] ?? 0,
      rank: rank,
    );
  }
}
