import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/duel.dart';
import '../models/duel_status.dart';
import '../logic/elo_calculator.dart';

class DuelRepository {
  // CHANGED: Lazy getter prevents early initialization crashes on Web
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<Duel> createDuel({
    required String hostUid,
    required String hostDisplayName,
    required String secretWord,
    required int wordLength,
    required String wordPack,
  }) async {
    final roomCode = _generateRoomCode();
    final docRef = _db.collection('duels').doc();

    final duel = Duel(
      id: docRef.id,
      roomCode: roomCode,
      wordLength: wordLength,
      wordPack: wordPack,
      status: DuelStatus.waiting,
      player1Id: hostUid,
      playerStates: {
        hostUid: DuelPlayerState(uid: hostUid, displayName: hostDisplayName),
      },
    );

    await docRef.set({
      ...duel.toJson(),
      'secretWord': secretWord.toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return duel;
  }

  Future<Duel> joinDuel({
    required String roomCode,
    required String joinerUid,
    required String joinerDisplayName,
  }) async {
    final query = await _db
        .collection('duels')
        .where('roomCode', isEqualTo: roomCode.toUpperCase())
        .where('status', isEqualTo: DuelStatus.waiting.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw StateError('Room not found or already started.');
    }

    final doc = query.docs.first;
    await doc.reference.update({
      'player2Id': joinerUid,
      'status': DuelStatus.active.name,
      'playerStates.$joinerUid': DuelPlayerState(uid: joinerUid, displayName: joinerDisplayName).toJson(),
    });

    final updated = await doc.reference.get();
    return Duel.fromJson(updated.id, updated.data()!);
  }

  Stream<Duel> watchDuel(String duelId) {
    return _db.collection('duels').doc(duelId).snapshots().map(
          (doc) => Duel.fromJson(doc.id, doc.data()!),
        );
  }

  Future<String> getSecretWord(String duelId) async {
    final doc = await _db.collection('duels').doc(duelId).get();
    return (doc.data()!['secretWord'] as String).toUpperCase();
  }

  Future<void> submitResult({
    required String duelId,
    required String uid,
    required int guessCount,
    required bool won,
    required int timeTakenSeconds,
  }) async {
    final docRef = _db.collection('duels').doc(duelId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final duel = Duel.fromJson(snapshot.id, snapshot.data()!);

      final updatedStates = Map<String, DuelPlayerState>.from(duel.playerStates);
      updatedStates[uid] = DuelPlayerState(
        uid: uid,
        displayName: updatedStates[uid]?.displayName ?? 'Player',
        guessCount: guessCount,
        finished: true,
        won: won,
        timeTakenSeconds: timeTakenSeconds,
      );

      final otherUid = duel.player1Id == uid ? duel.player2Id : duel.player1Id;
      final otherState = otherUid != null ? updatedStates[otherUid] : null;

      String? winnerId = duel.winnerId;
      var status = duel.status;

      if (otherState != null && otherState.finished) {
        final me = updatedStates[uid]!;
        if (me.won && !otherState.won) {
          winnerId = uid;
        } else if (!me.won && otherState.won) {
          winnerId = otherUid;
        } else if (me.won && otherState.won) {
          if (me.guessCount != otherState.guessCount) {
            winnerId = me.guessCount < otherState.guessCount ? uid : otherUid;
          } else {
            winnerId = (me.timeTakenSeconds ?? 999999) <= (otherState.timeTakenSeconds ?? 999999)
                ? uid
                : otherUid;
          }
        }
        status = DuelStatus.finished;
      }

      transaction.update(docRef, {
        'playerStates.$uid': updatedStates[uid]!.toJson(),
        'status': status.name,
        if (winnerId != null) 'winnerId': winnerId,
      });
    });
  }

  Future<(int, int)> applyEloUpdate({
    required String winnerUid,
    required String loserUid,
    required int winnerRating,
    required int loserRating,
  }) async {
    final (newWinnerRating, newLoserRating) = EloCalculator.calculate(
      ratingA: winnerRating,
      ratingB: loserRating,
      scoreA: 1.0,
    );

    await _db.collection('users').doc(winnerUid).update({'eloRating': newWinnerRating});
    await _db.collection('users').doc(loserUid).update({'eloRating': newLoserRating});

    return (newWinnerRating, newLoserRating);
  }
}