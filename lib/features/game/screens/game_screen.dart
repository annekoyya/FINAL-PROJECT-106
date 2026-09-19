import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/settings_controller.dart';
import '../../../data/models/game_mode.dart';
import '../../../data/repositories/achievements_repository.dart';
import '../../../data/repositories/firebase_sync_repository.dart';
import '../../../data/repositories/game_state_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/word_repository.dart';
import '../logic/game_controller.dart';
import '../widgets/game_grid.dart';
import '../widgets/keyboard.dart';
import 'results_sheet.dart';

/// Top-level route target. Builds a fresh [GameController] scoped to this
/// screen (so each mode - daily/practice/timed - gets its own game state)
/// and hands it down via Provider to the widget tree below.
class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, this.mode = GameMode.daily});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final wordRepository = context.read<WordRepository>();
    final settings = context.read<SettingsController>();
    _controller = GameController(
      wordRepository: wordRepository,
      gameStateRepository: GameStateRepository(),
      statsRepository: StatsRepository(),
      achievementsRepository: AchievementsRepository(),
      firebaseSyncRepository: context.read<FirebaseSyncRepository?>(),
      mode: widget.mode,
      hardMode: settings.hardMode,
    );
    _controller.init().then((_) => setState(() => _ready = true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _GameScreenBody(mode: widget.mode),
    );
  }
}

class _GameScreenBody extends StatefulWidget {
  final GameMode mode;
  const _GameScreenBody({required this.mode});

  @override
  State<_GameScreenBody> createState() => _GameScreenBodyState();
}

class _GameScreenBodyState extends State<_GameScreenBody> {
  late final ConfettiController _confetti;
  bool _resultsShown = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final settings = context.watch<SettingsController>();

    if (controller.status != GameStatus.playing && !_resultsShown) {
      _resultsShown = true;
      if (controller.status == GameStatus.won) _confetti.play();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ResultsSheet(controller: controller),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Wordie · ${_modeLabel(widget.mode)}'),
        centerTitle: true,
        actions: [
          if (widget.mode != GameMode.timed)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Hint (${controller.hintsRemaining} left)',
              onPressed: controller.hintsRemaining > 0 ? controller.useHint : null,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (widget.mode == GameMode.timed)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '⏱ ${controller.timeRemaining.inSeconds}s',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (controller.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(controller.errorMessage!),
                  ),
                if (controller.isCheckingWord)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Checking word…', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: GameGrid(
                      pastGuesses: controller.guesses,
                      currentGuess: controller.currentGuess,
                      wordLength: controller.wordLength,
                      maxAttempts: controller.maxAttempts,
                      shake: controller.shake,
                      colors: settings.tileColors,
                    ),
                  ),
                ),
                KeyboardWidget(
                  letterStatuses: controller.letterStatuses,
                  onKeyTap: controller.addLetter,
                  onEnter: controller.submitGuess,
                  onBackspace: controller.removeLetter,
                  colors: settings.tileColors,
                  hapticsEnabled: settings.hapticsEnabled,
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(GameMode mode) {
    switch (mode) {
      case GameMode.daily:
        return 'Daily';
      case GameMode.practice:
        return 'Practice';
      case GameMode.timed:
        return 'Timed';
    }
  }
}
