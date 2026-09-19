import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/logic/guess_evaluator.dart';
import '../../../data/models/game_mode.dart';
import '../../../data/models/guess_result.dart';
import '../../../data/models/letter_status.dart';
import '../../../data/models/stats.dart';
import '../../../data/repositories/achievements_repository.dart';
import '../../../data/repositories/game_state_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/word_repository.dart';
import '../../../data/repositories/firebase_sync_repository.dart';
import '../../achievements/logic/achievement_checker.dart';

enum GameStatus { playing, won, lost }

class GameController extends ChangeNotifier {
  final WordRepository wordRepository;
  final GameStateRepository gameStateRepository;
  final StatsRepository statsRepository;
  final AchievementsRepository achievementsRepository;
  final FirebaseSyncRepository? firebaseSyncRepository;

  final GameMode mode;
  final int wordLength;
  final int maxAttempts;
  final bool hardMode;

  late String _answer;
  final List<GuessResult> guesses = [];
  String currentGuess = '';
  GameStatus status = GameStatus.playing;
  String? errorMessage;
  bool shake = false;
  bool isCheckingWord = false; // true while awaiting the dictionary API
  int hintsRemaining = 1;

  Duration timeRemaining = const Duration(seconds: 60);
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  final Map<String, LetterStatus> letterStatuses = {};
  Stats stats = Stats();
  List<String> newlyUnlockedAchievementIds = [];

  GameController({
    required this.wordRepository,
    required this.gameStateRepository,
    required this.statsRepository,
    required this.achievementsRepository,
    this.firebaseSyncRepository,
    this.mode = GameMode.daily,
    this.wordLength = 5,
    this.maxAttempts = 6,
    this.hardMode = false,
  }) {
    _answer = mode == GameMode.daily ? wordRepository.dailyWord() : wordRepository.randomWord();
  }

  String get dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> init() async {
    stats = await statsRepository.load();

    if (mode == GameMode.daily) {
      final saved = await gameStateRepository.load(dateKey);
      if (saved != null) {
        final savedGuesses = (saved['guesses'] as List)
            .map((g) => GuessResult.fromJson(g as Map<String, dynamic>))
            .toList();
        guesses.addAll(savedGuesses);
        for (final g in savedGuesses) {
          _updateLetterStatuses(g);
        }
        status = GameStatus.values.firstWhere((s) => s.name == saved['status']);
      }
    }

    if (mode == GameMode.timed) {
      _stopwatch.start();
      _startTimer();
    } else {
      _stopwatch.start();
    }

    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (status != GameStatus.playing) {
        t.cancel();
        return;
      }
      if (timeRemaining.inSeconds <= 0) {
        t.cancel();
        status = GameStatus.lost;
        _onGameEnded();
      } else {
        timeRemaining -= const Duration(seconds: 1);
      }
      notifyListeners();
    });
  }

  void addLetter(String letter) {
    if (status != GameStatus.playing || isCheckingWord) return;
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

  void useHint() {
    if (hintsRemaining <= 0 || status != GameStatus.playing) return;
    final answerLetters = _answer.split('');
    for (var i = 0; i < wordLength; i++) {
      final alreadyTyped = i < currentGuess.length && currentGuess[i] == answerLetters[i];
      if (!alreadyTyped) {
        final padded = currentGuess.padRight(wordLength, ' ').split('');
        padded[i] = answerLetters[i];
        currentGuess = padded.join().trimRight();
        hintsRemaining--;
        notifyListeners();
        return;
      }
    }
  }

  bool _satisfiesHardMode(String guess) {
    if (!hardMode || guesses.isEmpty) return true;
    final lastResult = guesses.last;
    for (var i = 0; i < wordLength; i++) {
      if (lastResult.statuses[i] == LetterStatus.correct && guess[i] != lastResult.word[i]) {
        return false;
      }
    }
    for (var i = 0; i < wordLength; i++) {
      if (lastResult.statuses[i] == LetterStatus.present &&
          !guess.contains(lastResult.word[i])) {
        return false;
      }
    }
    return true;
  }

  /// Now async: validity is checked against the local word list first
  /// (instant), then the live dictionary API if the word isn't already
  /// known - this is what gives Wordie an effectively unlimited
  /// vocabulary instead of only accepting words from a bundled file.
  Future<void> submitGuess() async {
    if (status != GameStatus.playing || isCheckingWord) return;

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
    if (!_satisfiesHardMode(currentGuess)) {
      _flashError('Hard mode: must reuse revealed hints');
      return;
    }

    final result = GuessEvaluator.evaluate(currentGuess, _answer);
    guesses.add(result);
    _updateLetterStatuses(result);

    if (result.isWin) {
      status = GameStatus.won;
    } else if (guesses.length >= maxAttempts) {
      status = GameStatus.lost;
    }

    currentGuess = '';

    if (mode == GameMode.daily) {
      gameStateRepository.save(dateKey: dateKey, guesses: guesses, status: status.name);
    }

    if (status != GameStatus.playing) {
      await _onGameEnded();
    }

    notifyListeners();
  }

  Future<void> _onGameEnded() async {
    _timer?.cancel();
    _stopwatch.stop();

    final won = status == GameStatus.won;
    stats.gamesPlayed++;
    if (won) {
      stats.gamesWon++;
      stats.currentStreak++;
      stats.maxStreak = stats.maxStreak > stats.currentStreak ? stats.maxStreak : stats.currentStreak;
      if (guesses.length <= 6) {
        stats.guessDistribution[guesses.length - 1]++;
      }
    } else {
      stats.currentStreak = 0;
    }
    await statsRepository.save(stats);

    final unlockedIds = await achievementsRepository.loadUnlockedIds();
    final newlyUnlocked = AchievementChecker.checkNewUnlocks(
      won: won,
      guesses: guesses,
      stats: stats,
      alreadyUnlocked: unlockedIds,
    );
    if (newlyUnlocked.isNotEmpty) {
      newlyUnlockedAchievementIds = newlyUnlocked;
      await achievementsRepository.saveUnlockedIds({...unlockedIds, ...newlyUnlocked});
    }

    if (firebaseSyncRepository != null) {
      try {
        await firebaseSyncRepository!.pushStats(stats);
        if (mode == GameMode.daily) {
          await firebaseSyncRepository!.submitLeaderboardEntry(
            dailyPuzzleNumber: wordRepository.dailyPuzzleNumber(),
            guessCount: won ? guesses.length : null,
            timeTaken: _stopwatch.elapsed,
          );
        }
      } catch (_) {
        // Offline or Firebase not configured - ignore, local game still works.
      }
    }
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

  String buildShareText() {
    final puzzleNumber = wordRepository.dailyPuzzleNumber();
    final lines = guesses.map((g) {
      return g.statuses.map((s) {
        switch (s) {
          case LetterStatus.correct:
            return '🟩';
          case LetterStatus.present:
            return '🟨';
          default:
            return '⬜';
        }
      }).join();
    }).join('\n');

    final resultLabel = status == GameStatus.won ? '${guesses.length}/$maxAttempts' : 'X/$maxAttempts';
    final modeLabel = mode == GameMode.daily ? 'Wordie #$puzzleNumber' : 'Wordie (${mode.name})';
    return '$modeLabel $resultLabel\n\n$lines';
  }

  String get answer => _answer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
