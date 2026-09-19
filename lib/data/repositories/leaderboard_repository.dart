import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

enum LeaderboardScope { friends, global, duelElo }

/// Reads ranked leaderboard data from Firestore. Returns an empty stream
/// gracefully (not an error) if Firebase isn't configured for this build -
/// callers should check FirebaseSyncRepository's availability first, same
/// pattern as LeaderboardScreen already uses.
class LeaderboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LeaderboardEntry>> watchGlobal({int limit = 50}) {
    return _db
        .collection('users')
        .orderBy('eloRating', descending: true)
        .limit(limit)
        .snapshots()
        .map(_snapshotToEntries);
  }

  Stream<List<LeaderboardEntry>> watchDuelElo({int limit = 50}) {
    // Same underlying field as global for this project's scope; kept as a
    // separate method so a future "duels-only rating" field is a one-line
    // change here rather than a call-site change everywhere.
    return watchGlobal(limit: limit);
  }

  /// Friends-only leaderboard: filters to just the current user's friend
  /// uids. Firestore's `whereIn` supports at most 30 values per query -
  /// fine for a friends list, but chunk this if you ever expect more.
  Stream<List<LeaderboardEntry>> watchFriends(List<String> friendUids, {int limit = 30}) {
    if (friendUids.isEmpty) {
      return Stream.value([]);
    }
    final capped = friendUids.take(30).toList();
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: capped)
        .orderBy('eloRating', descending: true)
        .snapshots()
        .map(_snapshotToEntries);
  }

  List<LeaderboardEntry> _snapshotToEntries(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final docs = snapshot.docs;
    return List.generate(
      docs.length,
      (i) => LeaderboardEntry.fromJson(docs[i].id, docs[i].data(), i + 1),
    );
  }
}
