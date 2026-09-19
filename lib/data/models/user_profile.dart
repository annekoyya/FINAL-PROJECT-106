class UserProfile {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final int eloRating;
  final int rankGlobal;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.isAnonymous = true,
    this.eloRating = 1200,
    this.rankGlobal = 0,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'eloRating': eloRating,
        'rankGlobal': rankGlobal,
      };

  factory UserProfile.fromJson(String uid, Map<String, dynamic> json, {bool isAnonymous = false}) {
    return UserProfile(
      uid: uid,
      displayName: json['displayName'] ?? 'Player',
      photoUrl: json['photoUrl'],
      isAnonymous: isAnonymous,
      eloRating: json['eloRating'] ?? 1200,
      rankGlobal: json['rankGlobal'] ?? 0,
    );
  }
}
