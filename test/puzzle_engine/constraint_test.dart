import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier1_category.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier2_letter_rules.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier3_wordplay.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier4_container.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier5_combined.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

void main() {
  setUp(() {
    CategoryListLoader.clearCache();
  });

  group('Tier 1 — CategoryConstraint', () {
    test('is_animal validates correctly', () {
      CategoryListLoader.preload('animals', {'dog', 'cat', 'lion', 'eagle'});
      final constraint = tier1Constraints.firstWhere((c) => c.id == 'is_animal');

      expect(constraint.validate('dog'), isTrue);
      expect(constraint.validate('cat'), isTrue);
      expect(constraint.validate('LION'), isTrue); // case-insensitive
      expect(constraint.validate('apple'), isFalse);
      expect(constraint.validate('table'), isFalse);
    });

    test('is_color validates correctly', () {
      CategoryListLoader.preload('colors', {'red', 'blue', 'green', 'teal'});
      final constraint = tier1Constraints.firstWhere((c) => c.id == 'is_color');

      expect(constraint.validate('red'), isTrue);
      expect(constraint.validate('BLUE'), isTrue);
      expect(constraint.validate('purple'), isFalse); // not preloaded
    });

    test('filterWordList returns only matching words', () {
      CategoryListLoader.preload('animals', {'dog', 'cat', 'bee'});
      final constraint = tier1Constraints.firstWhere((c) => c.id == 'is_animal');

      final words = ['dog', 'apple', 'cat', 'tree', 'bee'];
      final filtered = constraint.filterWordList(words);
      expect(filtered, containsAll(['dog', 'cat', 'bee']));
      expect(filtered, isNot(contains('apple')));
      expect(filtered, isNot(contains('tree')));
    });
  });

  group('Tier 2 — SameFirstLastConstraint', () {
    const constraint = SameFirstLastConstraint();

    test('accepts words where first and last letters match', () {
      expect(constraint.validate('level'), isTrue);   // l...l
      expect(constraint.validate('radar'), isTrue);   // r...r
      expect(constraint.validate('civic'), isTrue);   // c...c
      expect(constraint.validate('did'), isTrue);     // d...d
    });

    test('rejects words where first and last letters differ', () {
      expect(constraint.validate('apple'), isFalse);  // a...e
      expect(constraint.validate('cat'), isFalse);    // c...t
      expect(constraint.validate('hello'), isFalse);  // h...o
    });

    test('is case-insensitive', () {
      expect(constraint.validate('LEVEL'), isTrue);
      expect(constraint.validate('Level'), isTrue);
    });
  });

  group('Tier 2 — NoRepeatedLettersConstraint', () {
    const constraint = NoRepeatedLettersConstraint();

    test('accepts words with all unique letters', () {
      expect(constraint.validate('place'), isTrue);
      expect(constraint.validate('bring'), isTrue);
      expect(constraint.validate('cat'), isTrue);
    });

    test('rejects words with repeated letters', () {
      expect(constraint.validate('apple'), isFalse); // pp
      expect(constraint.validate('level'), isFalse); // ll, ee
      expect(constraint.validate('hello'), isFalse); // ll
    });
  });

  group('Tier 2 — HasDoubleLetterConstraint', () {
    const constraint = HasDoubleLetterConstraint();

    test('accepts words with adjacent identical letters', () {
      expect(constraint.validate('happy'), isTrue);    // pp
      expect(constraint.validate('hello'), isTrue);    // ll
      expect(constraint.validate('balloon'), isTrue);  // ll, oo
      expect(constraint.validate('sleep'), isTrue);    // ee
    });

    test('rejects words without double letters', () {
      expect(constraint.validate('place'), isFalse);
      expect(constraint.validate('cat'), isFalse);
      expect(constraint.validate('bring'), isFalse);
    });
  });

  group('Tier 2 — ExactLengthConstraint', () {
    final constraint5 = ExactLengthConstraint(5);
    final constraint3 = ExactLengthConstraint(3);

    test('accepts words of exact length', () {
      expect(constraint5.validate('apple'), isTrue);
      expect(constraint5.validate('house'), isTrue);
      expect(constraint3.validate('cat'), isTrue);
    });

    test('rejects words of wrong length', () {
      expect(constraint5.validate('cat'), isFalse);
      expect(constraint5.validate('elephant'), isFalse);
      expect(constraint3.validate('apple'), isFalse);
    });
  });

  group('Tier 2 — StartsWithVowelConstraint', () {
    const constraint = StartsWithVowelConstraint();

    test('accepts words starting with vowels', () {
      expect(constraint.validate('apple'), isTrue);
      expect(constraint.validate('eagle'), isTrue);
      expect(constraint.validate('otter'), isTrue);
    });

    test('rejects words starting with consonants', () {
      expect(constraint.validate('cat'), isFalse);
      expect(constraint.validate('dog'), isFalse);
    });
  });

  group('Tier 2 — EndsWithVowelConstraint', () {
    const constraint = EndsWithVowelConstraint();

    test('accepts words ending with vowels', () {
      expect(constraint.validate('apple'), isTrue);  // e
      expect(constraint.validate('data'), isTrue);   // a
      expect(constraint.validate('echo'), isTrue);   // o
    });

    test('rejects words ending with consonants', () {
      expect(constraint.validate('cat'), isFalse);
      expect(constraint.validate('dog'), isFalse);
    });
  });

  group('Tier 2 — MoreVowelsThanConsonantsConstraint', () {
    const constraint = MoreVowelsThanConsonantsConstraint();

    test('accepts words with more vowels', () {
      expect(constraint.validate('audio'), isTrue);   // 4 vowels, 1 consonant
      expect(constraint.validate('queue'), isTrue);   // 4 vowels, 1 consonant
    });

    test('rejects words with equal or fewer vowels', () {
      expect(constraint.validate('cat'), isFalse);    // 1 vowel, 2 consonants
      expect(constraint.validate('rhythm'), isFalse); // 0 vowels, 6 consonants
    });
  });

  group('Tier 2 — ContainsVowelClusterConstraint', () {
    const constraint = ContainsVowelClusterConstraint();

    test('accepts words with consecutive vowels', () {
      expect(constraint.validate('rain'), isTrue);   // ai
      expect(constraint.validate('coat'), isTrue);   // oa
      expect(constraint.validate('audio'), isTrue);  // au, io
    });

    test('rejects words without consecutive vowels', () {
      expect(constraint.validate('cat'), isFalse);
      expect(constraint.validate('ship'), isFalse);
    });
  });

  group('Tier 3 — PalindromeConstraint', () {
    const constraint = PalindromeConstraint();

    test('accepts palindromes', () {
      expect(constraint.validate('racecar'), isTrue);
      expect(constraint.validate('civic'), isTrue);
      expect(constraint.validate('radar'), isTrue);
      expect(constraint.validate('level'), isTrue);
      expect(constraint.validate('noon'), isTrue);
    });

    test('rejects non-palindromes', () {
      expect(constraint.validate('hello'), isFalse);
      expect(constraint.validate('apple'), isFalse);
      expect(constraint.validate('cat'), isFalse);
    });

    test('is case-insensitive', () {
      expect(constraint.validate('RACECAR'), isTrue);
      expect(constraint.validate('Civic'), isTrue);
    });
  });

  group('Tier 3 — ReversalIsValidWordConstraint', () {
    final validWords = {'stop', 'pots', 'star', 'rats', 'dog', 'god'};
    final constraint = ReversalIsValidWordConstraint(validWords: validWords);

    test('accepts words whose reversal is also a valid word', () {
      expect(constraint.validate('stop'), isTrue);  // -> pots
      expect(constraint.validate('star'), isTrue);  // -> rats
      expect(constraint.validate('dog'), isTrue);   // -> god
    });

    test('rejects palindromes (reversal must be a different word)', () {
      expect(constraint.validate('civic'), isFalse); // palindrome, same word
    });

    test('rejects words whose reversal is not valid', () {
      expect(constraint.validate('cat'), isFalse);  // tac — not in validWords
    });
  });

  group('Tier 3 — AnagramConstraint', () {
    final constraint = AnagramConstraint('least');

    test('accepts anagrams of the target word', () {
      expect(constraint.validate('steal'), isTrue);
      expect(constraint.validate('slate'), isTrue);
      expect(constraint.validate('tales'), isTrue);
      expect(constraint.validate('stale'), isTrue);
    });

    test('rejects the target word itself', () {
      expect(constraint.validate('least'), isFalse);
    });

    test('rejects non-anagrams', () {
      expect(constraint.validate('stone'), isFalse);
      expect(constraint.validate('apple'), isFalse);
    });
  });

  group('Tier 4 — RemoveFirstLetterIsValidConstraint', () {
    // validWords does NOT contain 'at', 'og', or 'ox' so those will be rejected
    final validWords = {'train', 'rain', 'plane', 'lane'};
    final constraint = RemoveFirstLetterIsValidConstraint(validWords: validWords);

    test('accepts words that form a valid word when first letter removed', () {
      expect(constraint.validate('train'), isTrue); // -> rain (valid)
      expect(constraint.validate('plane'), isTrue); // -> lane (valid)
    });

    test('rejects words whose tail is not valid', () {
      expect(constraint.validate('cat'), isFalse);   // -> at — not in validWords
      expect(constraint.validate('dog'), isFalse);   // -> og — not in validWords
      expect(constraint.validate('fox'), isFalse);   // -> ox — not in validWords
    });
  });

  group('Tier 4 — RemoveLastLetterIsValidConstraint', () {
    final validWords = {'train', 'trains', 'plane', 'planes', 'cat', 'cats'};
    final constraint = RemoveLastLetterIsValidConstraint(validWords: validWords);

    test('accepts words that form a valid word when last letter removed', () {
      expect(constraint.validate('trains'), isTrue); // -> train (valid)
      expect(constraint.validate('planes'), isTrue); // -> plane (valid)
      expect(constraint.validate('cats'), isTrue);   // -> cat (valid)
    });

    test('rejects words whose prefix is not valid', () {
      expect(constraint.validate('apple'), isFalse); // appl — not in set
    });
  });

  group('Tier 4 — ContainsHiddenWordConstraint', () {
    final validWords = {'cat', 'are', 'arch', 'she', 'her', 'the'};
    final constraint = ContainsHiddenWordConstraint(validWords: validWords);

    test('accepts words with a hidden valid word strictly interior', () {
      // "arched" contains "arch" at positions 0-3, but we need interior
      // "scatter" contains "cat" at positions 1-3 (interior, not at start or end)
      expect(constraint.validate('scatter'), isTrue); // cat is interior
    });

    test('rejects words where the valid word is at start or end', () {
      // archway: "arch" starts at 0 — not interior
      // but "her" is at position 3 in "archery" and not at end
      expect(constraint.validate('arching'), isFalse); // arch is at start
    });
  });

  group('Tier 4 — StartsWithLetterConstraint', () {
    test('accepts words starting with specified letter', () {
      final constraint = StartsWithLetterConstraint('b');
      expect(constraint.validate('blue'), isTrue);
      expect(constraint.validate('BEAR'), isTrue);
    });

    test('rejects words starting with different letter', () {
      final constraint = StartsWithLetterConstraint('b');
      expect(constraint.validate('cat'), isFalse);
      expect(constraint.validate('apple'), isFalse);
    });
  });

  group('Tier 4 — ContainsLetterConstraint', () {
    test('accepts words containing the letter', () {
      final constraint = ContainsLetterConstraint('a');
      expect(constraint.validate('cat'), isTrue);
      expect(constraint.validate('APPLE'), isTrue);
    });

    test('rejects words not containing the letter', () {
      final constraint = ContainsLetterConstraint('z');
      expect(constraint.validate('cat'), isFalse);
    });
  });

  group('Tier 5 — CombinedConstraint', () {
    test('accepts words satisfying both sub-constraints', () {
      // Animal that starts with a vowel
      CategoryListLoader.clearCache();
      CategoryListLoader.preload('animals', {'eagle', 'otter', 'cat', 'dog'});

      final animalConstraint = tier1Constraints.firstWhere((c) => c.id == 'is_animal');
      const vowelConstraint = StartsWithVowelConstraint();

      final combined = CombinedConstraint(
        constraintA: animalConstraint,
        constraintB: vowelConstraint,
        id: 'animal_starts_vowel',
        displayText: 'An animal starting with a vowel',
      );

      expect(combined.validate('eagle'), isTrue);
      expect(combined.validate('otter'), isTrue);
      expect(combined.validate('cat'), isFalse);   // animal but no vowel start
      expect(combined.validate('apple'), isFalse); // starts with vowel but not animal
    });

    test('filterWordList applies both constraints', () {
      CategoryListLoader.clearCache();
      CategoryListLoader.preload('animals', {'eagle', 'otter', 'cat', 'dog'});

      final animalConstraint = tier1Constraints.firstWhere((c) => c.id == 'is_animal');
      const vowelConstraint = StartsWithVowelConstraint();

      final combined = CombinedConstraint(
        constraintA: animalConstraint,
        constraintB: vowelConstraint,
        id: 'animal_starts_vowel',
        displayText: 'An animal starting with a vowel',
      );

      final words = ['eagle', 'otter', 'cat', 'dog', 'apple', 'ant'];
      final filtered = combined.filterWordList(words);
      expect(filtered, containsAll(['eagle', 'otter']));
      expect(filtered, isNot(contains('cat')));
      expect(filtered, isNot(contains('dog')));
      expect(filtered, isNot(contains('apple')));
    });
  });
}
