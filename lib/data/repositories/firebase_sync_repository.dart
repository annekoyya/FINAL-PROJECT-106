import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stats.dart';

/// Optional cloud layer. The app works fully offline without this -
/// call [signInAnonymously] once at startup (see main.dart) and every
/// method below will silently no-op-safe (throwing is caught by callers)
/// if Firebase hasn't been configured for the project yet.
///
/// SETUP (see README.md "Firebase Setup" section for full steps):
/// 1. Run `flutterfire configure` in the project root - this generates
///    lib/firebase_options.dart for your own Firebase project.
/// 2. In Firestore, create these collections (they're created
///    automatically on first write, no manual setup required):
///      users/{uid}                -> synced stats document
///      leaderboard/{uid}          -> daily leaderboard entries
class FirebaseSyncRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  /// Anonymous auth is enough for a class project: it gives every install
  /// a stable UID for syncing without building a login screen. Swap this
  /// for email/Google sign-in later if you want cross-device login (F13).
  Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  Future<void> pushStats(Stats stats) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).set({
      ...stats.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Stats?> pullStats() async {
    final id = uid;
    if (id == null) return null;
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return Stats.fromJson(doc.data()!);
  }

  /// Submits a daily-mode result to the global leaderboard.
  /// [guessCount] should be null for a loss.
  Future<void> submitLeaderboardEntry({
    required int dailyPuzzleNumber,
    required int? guessCount,
    required Duration timeTaken,
    String displayName = 'Anonymous',
  }) async {
    final id = uid;
    if (id == null) return;
    await _db
        .collection('leaderboard')
        .doc('day_$dailyPuzzleNumber')
        .collection('entries')
        .doc(id)
        .set({
      'displayName': displayName,
      'guessCount': guessCount,
      'won': guessCount != null,
      'timeTakenSeconds': timeTaken.inSeconds,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches today's leaderboard, best (fewest guesses, then fastest) first.
  Stream<List<Map<String, dynamic>>> watchLeaderboard(int dailyPuzzleNumber) {
    return _db
        .collection('leaderboard')
        .doc('day_$dailyPuzzleNumber')
        .collection('entries')
        .where('won', isEqualTo: true)
        .orderBy('guessCount')
        .orderBy('timeTakenSeconds')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
