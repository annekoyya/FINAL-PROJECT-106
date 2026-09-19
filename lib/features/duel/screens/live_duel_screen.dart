import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/settings_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/duel_repository.dart';
import '../../../data/repositories/word_repository.dart';
import '../../game/widgets/game_grid.dart';
import '../../game/widgets/keyboard.dart';
import '../logic/duel_controller.dart';
import 'match_result_screen.dart';

/// Matches "Wordie - Live 1v1 Duel": your full grid on the left/top,
/// opponent's masked progress (filled/empty dots) on the right/top,
/// shared keyboard below.
class LiveDuelScreen extends StatefulWidget {
  final String duelId;
  const LiveDuelScreen({super.key, required this.duelId});

  @override
  State<LiveDuelScreen> createState() => _LiveDuelScreenState();
}

class _LiveDuelScreenState extends State<LiveDuelScreen> {
  DuelController? _controller;
  bool _ready = false;
  bool _navigatedToResults = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final auth = context.read<AuthRepository>();
    final uid = auth.currentUser?.uid ?? (await auth.signInAnonymously())?.uid;
    _controller = DuelController(
      duelRepository: context.read<DuelRepository>(),
      wordRepository: context.read<WordRepository>(),
      duelId: widget.duelId,
      myUid: uid!,
      myDisplayName: auth.currentUser?.displayName ?? 'Player',
    );
    await _controller!.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider.value(
      value: _controller!,
      child: const _LiveDuelBody(),
    );
  }
}

class _LiveDuelBody extends StatelessWidget {
  const _LiveDuelBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DuelController>();
    final settings = context.watch<SettingsController>();

    if (controller.bothFinished && !controller.isCheckingWord) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MatchResultScreen(controller: controller)),
        );
      });
    }

    final opponent = controller.opponentState;
    final opponentGuessCount = opponent?.guessCount ?? 0;

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        title: Text('Duel · ${controller.duel?.roomCode ?? ''}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text('Opponent', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(6, (i) {
                          final filled = i < opponentGuessCount;
                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? BrandColors.primary : BrandColors.primary.withOpacity(0.2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (controller.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(6)),
                child: Text(controller.errorMessage!, style: const TextStyle(color: Colors.white)),
              ),
            if (opponent?.finished == true && controller.status == LocalGameStatus.playing)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Chip(
                  label: Text(opponent!.won ? 'Opponent finished — keep going!' : 'Opponent is guessing…'),
                  backgroundColor: BrandColors.accentGold.withOpacity(0.5),
                ),
              ),
            Expanded(
              child: Center(
                child: GameGrid(
                  pastGuesses: controller.guesses,
                  currentGuess: controller.currentGuess,
                  wordLength: controller.wordLength,
                  maxAttempts: 6,
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
      ),
    );
  }
}
