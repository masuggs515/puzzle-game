import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';

/// First and last letter are the same.
class SameFirstLastConstraint extends Constraint {
  const SameFirstLastConstraint()
      : super(
          id: 'same_first_last',
          tier: 2,
          displayText: 'First and last letter are the same',
        );

  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    final lower = word.toLowerCase();
    return lower[0] == lower[lower.length - 1];
  }
}

/// All letters in the word are unique (no repetitions).
class NoRepeatedLettersConstraint extends Constraint {
  const NoRepeatedLettersConstraint()
      : super(
          id: 'no_repeated_letters',
          tier: 2,
          displayText: 'All letters are unique',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    return lower.split('').toSet().length == lower.length;
  }
}

/// Word contains at least one pair of adjacent identical letters.
class HasDoubleLetterConstraint extends Constraint {
  const HasDoubleLetterConstraint()
      : super(
          id: 'has_double_letter',
          tier: 2,
          displayText: 'Contains a double letter (e.g. LL, SS)',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    for (int i = 0; i < lower.length - 1; i++) {
      if (lower[i] == lower[i + 1]) return true;
    }
    return false;
  }
}

/// Word must be exactly a specified length.
class ExactLengthConstraint extends Constraint {
  final int length;

  ExactLengthConstraint(this.length)
      : super(
          id: 'exact_length_$length',
          tier: 2,
          displayText: 'Exactly $length letters long',
        );

  @override
  bool validate(String word) => word.length == length;
}

/// First letter is a vowel.
class StartsWithVowelConstraint extends Constraint {
  const StartsWithVowelConstraint()
      : super(
          id: 'starts_with_vowel',
          tier: 2,
          displayText: 'Starts with a vowel',
        );

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  @override
  bool validate(String word) {
    if (word.isEmpty) return false;
    return _vowels.contains(word[0].toLowerCase());
  }
}

/// Last letter is a vowel.
class EndsWithVowelConstraint extends Constraint {
  const EndsWithVowelConstraint()
      : super(
          id: 'ends_with_vowel',
          tier: 2,
          displayText: 'Ends with a vowel',
        );

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  @override
  bool validate(String word) {
    if (word.isEmpty) return false;
    return _vowels.contains(word[word.length - 1].toLowerCase());
  }
}

/// Strict alternating consonant-vowel or vowel-consonant pattern.
class AlternatingConsonantVowelConstraint extends Constraint {
  const AlternatingConsonantVowelConstraint()
      : super(
          id: 'alternating_consonant_vowel',
          tier: 2,
          displayText: 'Alternates consonants and vowels',
        );

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    final lower = word.toLowerCase();
    final isVowel = lower.split('').map((c) => _vowels.contains(c)).toList();
    for (int i = 1; i < isVowel.length; i++) {
      if (isVowel[i] == isVowel[i - 1]) return false;
    }
    return true;
  }
}

/// Word has more vowels than consonants.
class MoreVowelsThanConsonantsConstraint extends Constraint {
  const MoreVowelsThanConsonantsConstraint()
      : super(
          id: 'more_vowels_than_consonants',
          tier: 2,
          displayText: 'More vowels than consonants',
        );

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    int vowelCount = 0;
    int consonantCount = 0;
    for (final c in lower.split('')) {
      if (_vowels.contains(c)) {
        vowelCount++;
      } else {
        consonantCount++;
      }
    }
    return vowelCount > consonantCount;
  }
}

/// Word contains a cluster of 2+ consecutive vowels.
class ContainsVowelClusterConstraint extends Constraint {
  const ContainsVowelClusterConstraint()
      : super(
          id: 'contains_vowel_cluster',
          tier: 2,
          displayText: 'Contains two or more vowels in a row',
        );

  static const _vowels = {'a', 'e', 'i', 'o', 'u'};

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    int consecutive = 0;
    for (final c in lower.split('')) {
      if (_vowels.contains(c)) {
        consecutive++;
        if (consecutive >= 2) return true;
      } else {
        consecutive = 0;
      }
    }
    return false;
  }
}

/// All Tier 2 structural constraints.
final List<Constraint> tier2Constraints = [
  const SameFirstLastConstraint(),
  const NoRepeatedLettersConstraint(),
  const HasDoubleLetterConstraint(),
  ExactLengthConstraint(4),
  ExactLengthConstraint(5),
  ExactLengthConstraint(6),
  const StartsWithVowelConstraint(),
  const EndsWithVowelConstraint(),
  const AlternatingConsonantVowelConstraint(),
  const MoreVowelsThanConsonantsConstraint(),
  const ContainsVowelClusterConstraint(),
];
