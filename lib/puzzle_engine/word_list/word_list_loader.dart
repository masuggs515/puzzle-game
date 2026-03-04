import 'dart:io';

import 'package:puzzle_game/puzzle_engine/word_list/word_list_filter.dart';

export 'package:puzzle_game/puzzle_engine/word_list/word_list_model.dart';

class CategoryListLoader {
  static final Map<String, Set<String>> _cache = {};

  /// For CLI/test use — loads from dart:io
  static Set<String> loadFromFile(String categoryName, String basePath) {
    if (_cache.containsKey(categoryName)) return _cache[categoryName]!;
    final file = File('$basePath/$categoryName.txt');
    final content = file.existsSync() ? file.readAsStringSync() : '';
    final words = content
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();
    _cache[categoryName] = words;
    return words;
  }

  static void preload(String categoryName, Set<String> words) {
    _cache[categoryName] = words;
  }

  static Set<String> get(String categoryName) => _cache[categoryName] ?? {};

  static void clearCache() => _cache.clear();
}

class WordListLoader {
  final List<String> answerWords;
  final Set<String> allValidWords;

  WordListLoader({
    required this.answerWords,
    required this.allValidWords,
  });

  /// CLI factory — loads from dart:io
  factory WordListLoader.fromFiles({String basePath = 'assets/word_lists'}) {
    final answerFile = File('$basePath/answer_words.txt');
    final guessFile = File('$basePath/valid_guess_words.txt');

    final answerWords = answerFile.readAsLinesSync()
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty && WordListFilter.isValidAnswerWord(w))
        .toList();

    final validGuessWords = guessFile.existsSync()
        ? guessFile.readAsLinesSync()
            .map((w) => w.trim().toLowerCase())
            .where((w) => w.isNotEmpty && WordListFilter.isValidGuessWord(w))
            .toSet()
        : <String>{};

    // Load category lists
    final categoryDir = Directory('$basePath/category_lists');
    if (categoryDir.existsSync()) {
      for (final file in categoryDir.listSync().whereType<File>()) {
        final categoryName = file.uri.pathSegments.last.replaceAll('.txt', '');
        final words = file.readAsLinesSync()
            .map((w) => w.trim().toLowerCase())
            .where((w) => w.isNotEmpty)
            .toSet();
        CategoryListLoader.preload(categoryName, words);
      }
    }

    return WordListLoader(
      answerWords: answerWords,
      allValidWords: {...answerWords, ...validGuessWords},
    );
  }

  /// In-memory constructor for testing — accepts pre-loaded content strings
  factory WordListLoader.fromStrings({
    required String answerWordsContent,
    required String validGuessWordsContent,
    Map<String, String> categoryContents = const {},
  }) {
    final answerWords = answerWordsContent
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty && WordListFilter.isValidAnswerWord(w))
        .toList();

    final validGuessWords = validGuessWordsContent
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty && WordListFilter.isValidGuessWord(w))
        .toSet();

    for (final entry in categoryContents.entries) {
      final words = entry.value
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.isNotEmpty)
          .toSet();
      CategoryListLoader.preload(entry.key, words);
    }

    return WordListLoader(
      answerWords: answerWords,
      allValidWords: {...answerWords, ...validGuessWords},
    );
  }
}
