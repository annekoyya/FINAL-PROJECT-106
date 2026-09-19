import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../../core/theme/app_colors.dart';
import '../../../data/models/letter_status.dart';

class KeyboardWidget extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;
  final Map<String, LetterStatus> letterStatuses;
  final TileColors colors;
  final bool hapticsEnabled;

  const KeyboardWidget({
    super.key,
    required this.onKeyTap,
    required this.onEnter,
    required this.onBackspace,
    required this.letterStatuses,
    this.colors = TileColors.classic,
    this.hapticsEnabled = true,
  });

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BACK'],
  ];

  Color _keyColor(String key, int keyIndexInRow) {
    final status = letterStatuses[key];
    switch (status) {
      case LetterStatus.correct:
        return colors.correct;
      case LetterStatus.present:
        return colors.present;
      case LetterStatus.absent:
        return colors.absent;
      default:
        // Alternate the two unused-key pastel tones for visual texture,
        // like the two "Button colors" swatches.
        return keyIndexInRow.isEven ? KeyboardColors.keyA : KeyboardColors.keyB;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: KeyboardColors.background,
      ),
      child: Column(
        children: List.generate(_rows.length, (rowIdx) {
          final row = _rows[rowIdx];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(row.length, (keyIdx) {
                final key = row[keyIdx];
                final isWide = key == 'ENTER' || key == 'BACK';
                final bg = key == 'ENTER' || key == 'BACK'
                    ? KeyboardColors.keyB
                    : _keyColor(key, keyIdx);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    width: isWide ? 58 : 34,
                    height: 50,
                    child: Material(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (hapticsEnabled) HapticFeedback.lightImpact();
                          if (key == 'ENTER') {
                            onEnter();
                          } else if (key == 'BACK') {
                            onBackspace();
                          } else {
                            onKeyTap(key);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: KeyboardColors.border.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: key == 'BACK'
                              ? const Icon(Icons.backspace_outlined,
                                  size: 18, color: KeyboardColors.textColor)
                              : Text(
                                  key == 'ENTER' ? 'ENTER' : key,
                                  style: TextStyle(
                                    color: KeyboardColors.textColor,
                                    fontSize: key == 'ENTER' ? 11 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
