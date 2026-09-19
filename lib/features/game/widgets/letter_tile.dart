import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/letter_status.dart';

class LetterTile extends StatelessWidget {
  final String letter;
  final LetterStatus status;
  final TileColors colors;

  const LetterTile({
    super.key,
    required this.letter,
    this.status = LetterStatus.initial,
    this.colors = TileColors.classic,
  });

  Color _bg() {
    switch (status) {
      case LetterStatus.correct:
        return colors.correct;
      case LetterStatus.present:
        return colors.present;
      case LetterStatus.absent:
        return colors.absent;
      case LetterStatus.initial:
        return Colors.white;
    }
  }

  Color _textColor() {
    // Dark text reads better on these light pastel tiles than white does.
    return status == LetterStatus.initial ? const Color(0xFF4A4458) : const Color(0xFF3A3A3C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _bg(),
        border: Border.all(
          color: status == LetterStatus.initial ? colors.emptyBorder : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textColor()),
      ),
    );
  }
}
