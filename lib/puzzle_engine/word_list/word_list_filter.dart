import 'package:puzzle_game/puzzle_engine/validation/profanity_filter.dart';

class WordListFilter {
  static bool isValidAnswerWord(String word) {
    if (word.length < 3 || word.length > 8) return false;
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word)) return false;
    if (ProfanityFilter.isBlocked(word)) return false;
    return true;
  }

  static bool isValidGuessWord(String word) {
    if (word.length < 3 || word.length > 12) return false;
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word)) return false;
    if (ProfanityFilter.isBlocked(word)) return false;
    return true;
  }
}
