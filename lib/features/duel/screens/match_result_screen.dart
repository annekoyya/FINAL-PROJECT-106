import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/duel_controller.dart';

/// Matches "Wordie - Match Result...": secret word reveal, guess-by-guess
/// comparison, a lightweight achievement callout, share + rematch actions.
class MatchResultScreen extends StatelessWidget {
  final DuelController controller;
  const MatchResultScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final iWon = controller.winnerId == controller.myUid;
    final opponent = controller.opponentState;

    // Lightweight, session-only achievement callout for a strong duel win.
    // For persistence across sessions, route this through
    // AchievementChecker/AchievementsRepository the same way solo Daily
    // Mode does in GameController._onGameEnded().
    final sharpMind = iWon && controller.guesses.length <= 3;

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.background,
        elevation: 0,
        title: const Text('Live Match Duel'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Chip(
                label: Text(iWon ? 'VICTORY!' : 'DEFEATED'),
                backgroundColor: iWon ? BrandColors.accentMint : Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              const Text('Match Completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('THE SECRET WORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controller.secretWordForResultsScreen.split('').map((letter) {
                  return Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: BrandColors.accentMint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _ResultRow(
                label: 'You',
                guesses: controller.guesses.length,
                won: iWon,
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: opponent?.displayName ?? 'Opponent',
                guesses: opponent?.guessCount ?? 0,
                won: !iWon,
              ),
              if (sharpMind) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrandColors.accentGold.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: BrandColors.textDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACHIEVEMENT UNLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('Sharp Mind — Win a 1v1 Duel in 3 guesses or fewer',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Results Grid'),
                  onPressed: () => Share.share(
                    'Wordie Duel · ${iWon ? "Won" : "Lost"} in ${controller.guesses.length} guesses vs ${opponent?.displayName ?? "opponent"}!',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/duel/setup'),
                  child: const Text('Rematch'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final int guesses;
  final bool won;
  const _ResultRow({required this.label, required this.guesses, required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: won ? BrandColors.accentMint.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('$guesses guesses'),
          if (won) ...[
            const SizedBox(width: 8),
            const Icon(Icons.emoji_events, size: 16, color: BrandColors.textDark),
            const Text(' WINNER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
