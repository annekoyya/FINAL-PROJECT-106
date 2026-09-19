import 'duel_status.dart';

/// A single player's progress within a duel - guesses, timing, completion.
class DuelPlayerState {
  final String uid;
  final String displayName;
  final int guessCount;
  final bool finished;
  final bool won;
  final int? timeTakenSeconds;

  const DuelPlayerState({
    required this.uid,
    required this.displayName,
    this.guessCount = 0,
    this.finished = false,
    this.won = false,
    this.timeTakenSeconds,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'guessCount': guessCount,
        'finished': finished,
        'won': won,
        'timeTakenSeconds': timeTakenSeconds,
      };

  factory DuelPlayerState.fromJson(Map<String, dynamic> json) => DuelPlayerState(
        uid: json['uid'],
        displayName: json['displayName'] ?? 'Player',
        guessCount: json['guessCount'] ?? 0,
        finished: json['finished'] ?? false,
        won: json['won'] ?? false,
        timeTakenSeconds: json['timeTakenSeconds'],
      );
}

class Duel {
  final String id;
  final String roomCode;
  final int wordLength;
  final String wordPack;
  final DuelStatus status;
  final String player1Id;
  final String? player2Id;
  final String? winnerId;
  final Map<String, DuelPlayerState> playerStates; // uid -> state

  const Duel({
    required this.id,
    required this.roomCode,
    required this.wordLength,
    required this.wordPack,
    required this.status,
    required this.player1Id,
    this.player2Id,
    this.winnerId,
    this.playerStates = const {},
  });

  factory Duel.fromJson(String id, Map<String, dynamic> json) {
    final statesJson = (json['playerStates'] as Map<String, dynamic>?) ?? {};
    return Duel(
      id: id,
      roomCode: json['roomCode'] ?? '',
      wordLength: json['wordLength'] ?? 5,
      wordPack: json['wordPack'] ?? 'general',
      status: DuelStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'waiting'),
        orElse: () => DuelStatus.waiting,
      ),
      player1Id: json['player1Id'],
      player2Id: json['player2Id'],
      winnerId: json['winnerId'],
      playerStates: statesJson.map(
        (k, v) => MapEntry(k, DuelPlayerState.fromJson(Map<String, dynamic>.from(v))),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'wordLength': wordLength,
        'wordPack': wordPack,
        'status': status.name,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'winnerId': winnerId,
        'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
      };
}
