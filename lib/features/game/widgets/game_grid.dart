import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/guess_result.dart';
import 'letter_tile.dart';

class GameGrid extends StatelessWidget {
  final List<GuessResult> pastGuesses;
  final String currentGuess;
  final int maxAttempts;
  final int wordLength;
  final bool shake;
  final TileColors colors;

  const GameGrid({
    super.key,
    required this.pastGuesses,
    required this.currentGuess,
    this.maxAttempts = 6,
    this.wordLength = 5,
    this.shake = false,
    this.colors = TileColors.classic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxAttempts, (rowIndex) {
        if (rowIndex < pastGuesses.length) {
          final result = pastGuesses[rowIndex];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              wordLength,
              (i) => LetterTile(
                letter: result.word[i],
                status: result.statuses[i],
                colors: colors,
              ),
            ),
          );
        } else if (rowIndex == pastGuesses.length) {
          final row = Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(wordLength, (i) {
              final letter = i < currentGuess.length ? currentGuess[i] : '';
              return LetterTile(letter: letter, colors: colors);
            }),
          );
          return TweenAnimationBuilder<double>(
            key: ValueKey(shake),
            tween: Tween(begin: 0, end: shake ? 1 : 0),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              final offset = shake ? (4 * (0.5 - (value - 0.5).abs()) * 8) : 0.0;
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: row,
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(wordLength, (i) => LetterTile(letter: '', colors: colors)),
          );
        }
      }),
    );
  }
}
