import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_filter.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';
import 'package:puzzle_game/puzzle_engine/validation/profanity_filter.dart';

void main() {
  group('WordListFilter', () {
    group('isValidAnswerWord', () {
      test('accepts 3-8 letter alphabetic words', () {
        expect(WordListFilter.isValidAnswerWord('cat'), isTrue);
        expect(WordListFilter.isValidAnswerWord('apple'), isTrue);
        expect(WordListFilter.isValidAnswerWord('absolute'), isTrue); // 8 letters
      });

      test('rejects words shorter than 3 characters', () {
        expect(WordListFilter.isValidAnswerWord('at'), isFalse);
        expect(WordListFilter.isValidAnswerWord('a'), isFalse);
        expect(WordListFilter.isValidAnswerWord(''), isFalse);
      });

      test('rejects words longer than 8 characters', () {
        expect(WordListFilter.isValidAnswerWord('abcdefghi'), isFalse); // 9 letters
        expect(WordListFilter.isValidAnswerWord('absolutely'), isFalse); // 10 letters
      });

      test('rejects words with non-alphabetic characters', () {
        expect(WordListFilter.isValidAnswerWord('cat1'), isFalse);
        expect(WordListFilter.isValidAnswerWord('cat-'), isFalse);
        expect(WordListFilter.isValidAnswerWord("can't"), isFalse);
      });

      test('rejects profanity', () {
        expect(WordListFilter.isValidAnswerWord('shit'), isFalse);
        expect(WordListFilter.isValidAnswerWord('fuck'), isFalse);
      });
    });

    group('isValidGuessWord', () {
      test('accepts 3-12 letter words', () {
        expect(WordListFilter.isValidGuessWord('cat'), isTrue);
        expect(WordListFilter.isValidGuessWord('extraordinary'), isFalse); // 13 letters
        expect(WordListFilter.isValidGuessWord('caterpillar'), isTrue); // 11 letters
        expect(WordListFilter.isValidGuessWord('caterpillars'), isTrue); // 12 letters
      });

      test('rejects words shorter than 3 characters', () {
        expect(WordListFilter.isValidGuessWord('at'), isFalse);
      });

      test('rejects words longer than 12 characters', () {
        expect(WordListFilter.isValidGuessWord('internationally'), isFalse);
      });
    });
  });

  group('ProfanityFilter', () {
    test('blocks known profanity', () {
      expect(ProfanityFilter.isBlocked('shit'), isTrue);
      expect(ProfanityFilter.isBlocked('fuck'), isTrue);
      expect(ProfanityFilter.isBlocked('cunt'), isTrue);
    });

    test('is case-insensitive', () {
      expect(ProfanityFilter.isBlocked('SHIT'), isTrue);
      expect(ProfanityFilter.isBlocked('Fuck'), isTrue);
    });

    test('does not block clean words', () {
      expect(ProfanityFilter.isBlocked('apple'), isFalse);
      expect(ProfanityFilter.isBlocked('ship'), isFalse);
      expect(ProfanityFilter.isBlocked('pass'), isFalse);
    });
  });

  group('CategoryListLoader', () {
    setUp(() {
      CategoryListLoader.clearCache();
    });

    test('preload and get returns the preloaded words', () {
      CategoryListLoader.preload('test_category', {'dog', 'cat', 'bird'});
      final result = CategoryListLoader.get('test_category');
      expect(result, containsAll(['dog', 'cat', 'bird']));
    });

    test('get returns empty set for unknown category', () {
      final result = CategoryListLoader.get('nonexistent');
      expect(result, isEmpty);
    });
  });

  group('WordListLoader.fromStrings', () {
    test('parses answer words from string content', () {
      final loader = WordListLoader.fromStrings(
        answerWordsContent: 'apple\nbanana\ncat\ndog\n',
        validGuessWordsContent: '',
      );
      expect(loader.answerWords, containsAll(['apple', 'cat', 'dog']));
      // 'banana' is 6 letters — should be included
      expect(loader.answerWords, contains('banana'));
    });

    test('filters out too-short words', () {
      final loader = WordListLoader.fromStrings(
        answerWordsContent: 'ab\ncat\ndog\n',
        validGuessWordsContent: '',
      );
      expect(loader.answerWords, isNot(contains('ab')));
      expect(loader.answerWords, contains('cat'));
    });

    test('filters out too-long words', () {
      final loader = WordListLoader.fromStrings(
        answerWordsContent: 'cat\nremarkable\n', // remarkable is 10 chars
        validGuessWordsContent: '',
      );
      expect(loader.answerWords, contains('cat'));
      expect(loader.answerWords, isNot(contains('remarkable')));
    });

    test('preloads category lists from category contents', () {
      CategoryListLoader.clearCache();
      WordListLoader.fromStrings(
        answerWordsContent: 'cat\ndog\nlion\n',
        validGuessWordsContent: '',
        categoryContents: {
          'animals': 'cat\ndog\nlion\n',
        },
      );
      expect(CategoryListLoader.get('animals'), containsAll(['cat', 'dog', 'lion']));
    });

    test('allValidWords includes both answer and guess words', () {
      final loader = WordListLoader.fromStrings(
        answerWordsContent: 'cat\ndog\n',
        validGuessWordsContent: 'feline\ncanine\n',
      );
      expect(loader.allValidWords, contains('cat'));
      expect(loader.allValidWords, contains('feline'));
    });
  });
}
