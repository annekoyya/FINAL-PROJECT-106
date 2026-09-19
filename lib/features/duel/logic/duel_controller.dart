import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/logic/guess_evaluator.dart';
import '../../../data/models/duel.dart';
import '../../../data/models/duel_status.dart';
import '../../../data/models/guess_result.dart';
import '../../../data/models/letter_status.dart';
import '../../../data/repositories/duel_repository.dart';
import '../../../data/repositories/word_repository.dart';

enum LocalGameStatus { playing, won, lost }

/// Drives a single player's side of an async 1v1 duel: typing, guess
/// evaluation (via the same duplicate-letter-safe algorithm as solo play),
/// and submitting the final result to Firestore - while separately
/// listening to the shared duel document for the opponent's masked
/// progress and the eventual authoritative winner.
///
/// See DuelRepository's class doc for the important caveat: in this zip,
/// evaluation happens client-side because no Cloud Function is deployed.
/// The secret word is fetched once via [DuelRepository.getSecretWord] and
/// never re-requested or displayed except on the results screen.
class DuelController extends ChangeNotifier {
  final DuelRepository duelRepository;
  final WordRepository wordRepository;
  final String duelId;
  final String myUid;
  final String myDisplayName;

  late String _secretWord;
  int wordLength = 5;
  final List<GuessResult> guesses = [];
  String currentGuess = '';
  LocalGameStatus status = LocalGameStatus.playing;
  bool isCheckingWord = false;
  bool shake = false;
  String? errorMessage;

  Duel? duel; // latest snapshot from the live stream
  StreamSubscription<Duel>? _subscription;
  final Stopwatch _stopwatch = Stopwatch();

  final Map<String, LetterStatus> letterStatuses = {};

  DuelController({
    required this.duelRepository,
    required this.wordRepository,
    required this.duelId,
    required this.myUid,
    required this.myDisplayName,
  });

  String? get opponentUid {
    final d = duel;
    if (d == null) return null;
    return d.player1Id == myUid ? d.player2Id : d.player1Id;
  }

  DuelPlayerState? get opponentState {
    final uid = opponentUid;
    if (uid == null || duel == null) return null;
    return duel!.playerStates[uid];
  }

  bool get bothFinished => duel?.status == DuelStatus.finished;
  String? get winnerId => duel?.winnerId;

  Future<void> init() async {
    _secretWord = await duelRepository.getSecretWord(duelId);
    wordLength = _secretWord.length;
    _stopwatch.start();

    _subscription = duelRepository.watchDuel(duelId).listen((updated) {
      duel = updated;
      notifyListeners();
    });
  }

  void addLetter(String letter) {
    if (status != LocalGameStatus.playing || isCheckingWord) return;
    if (currentGuess.length >= wordLength) return;
    currentGuess += letter;
    notifyListeners();
  }

  void removeLetter() {
    if (isCheckingWord) return;
    if (currentGuess.isEmpty) return;
    currentGuess = currentGuess.substring(0, currentGuess.length - 1);
    notifyListeners();
  }

  Future<void> submitGuess() async {
    if (status != LocalGameStatus.playing || isCheckingWord) return;
    if (currentGuess.length != wordLength) {
      _flashError('Not enough letters');
      return;
    }

    isCheckingWord = true;
    notifyListeners();
    final valid = await wordRepository.isValidGuess(currentGuess);
    isCheckingWord = false;

    if (!valid) {
      _flashError('Not in word list');
      return;
    }

    final result = GuessEvaluator.evaluate(currentGuess, _secretWord);
    guesses.add(result);
    _updateLetterStatuses(result);
    currentGuess = '';

    if (result.isWin) {
      status = LocalGameStatus.won;
    } else if (guesses.length >= 6) {
      status = LocalGameStatus.lost;
    }

    if (status != LocalGameStatus.playing) {
      _stopwatch.stop();
      await duelRepository.submitResult(
        duelId: duelId,
        uid: myUid,
        guessCount: guesses.length,
        won: status == LocalGameStatus.won,
        timeTakenSeconds: _stopwatch.elapsed.inSeconds,
      );
    }

    notifyListeners();
  }

  void _updateLetterStatuses(GuessResult result) {
    for (var i = 0; i < result.word.length; i++) {
      final letter = result.word[i];
      final newStatus = result.statuses[i];
      final existing = letterStatuses[letter];
      if (existing == LetterStatus.correct) continue;
      if (existing == LetterStatus.present && newStatus == LetterStatus.absent) continue;
      letterStatuses[letter] = newStatus;
    }
  }

  void _flashError(String message) {
    errorMessage = message;
    shake = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 900), () {
      errorMessage = null;
      shake = false;
      notifyListeners();
    });
  }

  String get secretWordForResultsScreen => _secretWord;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
