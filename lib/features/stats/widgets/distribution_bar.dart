import 'package:flutter/material.dart';

class DistributionBar extends StatelessWidget {
  final int guessNumber;
  final int count;
  final int maxCount;

  const DistributionBar({super.key, required this.guessNumber, required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final widthFraction = maxCount == 0 ? 0.05 : (count / maxCount).clamp(0.05, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text('$guessNumber')),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFraction,
              child: Container(
                height: 22,
                color: const Color(0xFF6AAA64),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 6),
                child: Text('$count', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
