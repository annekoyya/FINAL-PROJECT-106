import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class DictionaryApiService {
  static const _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  final http.Client _client;
  final Map<String, bool> _validityCache = {};
  final Map<String, String?> _definitionCache = {};

  DictionaryApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<bool?> isValidWord(String word) async {
    final normalized = word.toLowerCase();
    if (_validityCache.containsKey(normalized)) {
      return _validityCache[normalized];
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/$normalized'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        _validityCache[normalized] = true;
        return true;
      } else if (response.statusCode == 404) {
        _validityCache[normalized] = false;
        return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> definitionFor(String word) async {
    final normalized = word.toLowerCase();
    if (_definitionCache.containsKey(normalized)) {
      return _definitionCache[normalized];
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/$normalized'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        _definitionCache[normalized] = null;
        return null;
      }

      final decoded = convert.jsonDecode(response.body) as List;
      if (decoded.isEmpty) return null;

      final meanings = decoded.first['meanings'] as List?;
      if (meanings == null || meanings.isEmpty) return null;

      final definitions = meanings.first['definitions'] as List?;
      if (definitions == null || definitions.isEmpty) return null;

      final definition = definitions.first['definition'] as String?;
      _definitionCache[normalized] = definition;
      return definition;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}