import 'dart:math' as math;

/// Standard Elo rating update, used for Wordie's ranked duel ladder.
///
/// NOTE ON PRODUCTION USE: this same formula should ultimately run inside
/// a Cloud Function triggered when a duel's status becomes "finished" -
/// never trust a client to report its own new rating in a shipped,
/// competitive product. It's included here client-side so Duel Mode is
/// fully demoable without a deployed backend; see the reference
/// Cloud Function noted in README.md before treating ranked play as
/// tamper-proof.
class EloCalculator {
  static const int _kFactor = 32;

  /// Returns (newRatingA, newRatingB).
  /// [scoreA] is 1.0 for a win, 0.0 for a loss, 0.5 for a draw (A's perspective).
  static (int, int) calculate({
    required int ratingA,
    required int ratingB,
    required double scoreA,
  }) {
    final expectedA = 1 / (1 + math.pow(10, (ratingB - ratingA) / 400));
    final expectedB = 1 - expectedA;
    final scoreB = 1 - scoreA;

    final newRatingA = (ratingA + _kFactor * (scoreA - expectedA)).round();
    final newRatingB = (ratingB + _kFactor * (scoreB - expectedB)).round();

    return (newRatingA, newRatingB);
  }
}
