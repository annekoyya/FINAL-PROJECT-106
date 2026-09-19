import 'dart:convert' as convert;
import 'package:flutter/services.dart' show rootBundle;
import 'dictionary_api_service.dart';
import 'remote_word_list_service.dart';

class WordRepository {
  final RemoteWordListService _remoteService;
  final DictionaryApiService _dictionaryService;

  List<String> _answers = [];
  List<String> _validGuesses = [];
  Map<String, String>? _bundledDefinitions;

  WordRepository({
    RemoteWordListService? remoteService,
    DictionaryApiService? dictionaryService,
  })  : _remoteService = remoteService ?? RemoteWordListService(),
        _dictionaryService = dictionaryService ?? DictionaryApiService();

  Future<void> load() async {
    final answersJson = await rootBundle.loadString('assets/words/answers.json');
    final guessesJson = await rootBundle.loadString('assets/words/valid_guesses.json');
    final defsJson = await rootBundle.loadString('assets/words/definitions.json');

    _answers = List<String>.from(convert.jsonDecode(answersJson) as List);
    _validGuesses = List<String>.from(convert.jsonDecode(guessesJson) as List);
    _bundledDefinitions = Map<String, String>.from(convert.jsonDecode(defsJson) as Map);

    final cached = await _remoteService.loadCached();
    if (cached != null && cached.isNotEmpty) {
      _answers = {..._answers, ...cached}.toList();
      _validGuesses = {..._validGuesses, ...cached}.toList();
    }
  }

  Future<bool> refreshWordListFromRemote() async {
    final success = await _remoteService.refresh();
    if (success) {
      final cached = await _remoteService.loadCached();
      if (cached != null) {
        _answers = {..._answers, ...cached}.toList();
        _validGuesses = {..._validGuesses, ...cached}.toList();
      }
    }
    return success;
  }

  Future<DateTime?> wordListLastUpdated() => _remoteService.lastUpdated();

  Future<bool> isValidGuess(String word) async {
    final upper = word.toUpperCase();
    if (_validGuesses.contains(upper) || _answers.contains(upper)) {
      return true;
    }

    final apiResult = await _dictionaryService.isValidWord(word);
    if (apiResult == true) {
      _validGuesses.add(upper);
      return true;
    }
    if (apiResult == false) {
      return false;
    }
    return false;
  }

  Future<String?> definitionFor(String word) async {
    final bundled = _bundledDefinitions?[word.toUpperCase()];
    if (bundled != null) return bundled;
    return _dictionaryService.definitionFor(word);
  }

  String dailyWord({DateTime? forDate}) {
    final date = forDate ?? DateTime.now();
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = date.difference(epoch).inDays;
    final index = daysSinceEpoch % _answers.length;
    return _answers[index];
  }

  int dailyPuzzleNumber({DateTime? forDate}) {
    final date = forDate ?? DateTime.now();
    final epoch = DateTime(2024, 1, 1);
    return date.difference(epoch).inDays;
  }

  String randomWord() {
    final index = DateTime.now().microsecondsSinceEpoch % _answers.length;
    return _answers[index];
  }

  int get wordCount => _answers.length;

  void dispose() => _dictionaryService.dispose();
}