import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../logic/game_controller.dart';

class ResultsSheet extends StatelessWidget {
  final GameController controller;
  const ResultsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final won = controller.status == GameStatus.won;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            won ? '🎉 You got it in ${controller.guesses.length}!' : '😔 So close!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The word was ${controller.answer}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (controller.newlyUnlockedAchievementIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '🏆 New achievement${controller.newlyUnlockedAchievementIds.length > 1 ? 's' : ''} unlocked!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () => Share.share(controller.buildShareText()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
