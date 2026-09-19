import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Downloads a larger word list from a remote JSON endpoint and caches it
/// to local disk so the game has a growing, offline-available vocabulary
/// instead of being stuck with the small list bundled in assets/.
///
/// Point [remoteUrl] at any endpoint that returns a plain JSON array of
/// uppercase strings, e.g. a raw GitHub file of 5-letter English words.
class RemoteWordListService {
  static const _lastUpdatedKey = 'word_list_last_updated';
  static const _cacheFileName = 'cached_word_list.json';

  final String remoteUrl;

  RemoteWordListService({
    this.remoteUrl =
        'https://raw.githubusercontent.com/dwyl/english-words/master/words_dictionary.json',
  });

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  /// Returns the cached word list from disk, or null if nothing's been
  /// downloaded yet (first run / never updated).
  Future<List<String>?> loadCached() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final list = List<String>.from(jsonDecode(raw));
      return list.map((w) => w.toUpperCase()).toList();
    } catch (_) {
      return null; // corrupted cache - fall back to bundled list
    }
  }

  /// Attempts to fetch a fresh word list and overwrite the local cache.
  /// Returns true on success, false if offline/failed (caller should keep
  /// using whatever's already cached or bundled).
  Future<bool> refresh({int wordLength = 5, int maxWords = 3000}) async {
    try {
      final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);

      // Handles both a plain array response and a {"word": 1, ...} map
      // response (like dwyl/english-words), normalizing either into a
      // clean list of same-length alphabetic words.
      final List<String> words = decoded is List
          ? List<String>.from(decoded)
          : (decoded as Map<String, dynamic>).keys.toList();

      final filtered = words
          .map((w) => w.toUpperCase())
          .where((w) => w.length == wordLength && RegExp(r'^[A-Z]+$').hasMatch(w))
          .toSet() // dedupe
          .take(maxWords)
          .toList();

      if (filtered.isEmpty) return false;

      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(filtered));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());

      return true;
    } catch (_) {
      return false; // offline or endpoint unreachable - safe no-op
    }
  }

  Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastUpdatedKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
