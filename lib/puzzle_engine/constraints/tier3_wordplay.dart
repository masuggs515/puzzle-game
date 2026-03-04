import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';

/// Word reads the same forwards and backwards.
class PalindromeConstraint extends Constraint {
  const PalindromeConstraint()
      : super(
          id: 'palindrome',
          tier: 3,
          displayText: 'Reads the same forwards and backwards',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    return lower == lower.split('').reversed.join();
  }
}

/// Reversing the word produces another valid English word.
class ReversalIsValidWordConstraint extends Constraint {
  final Set<String> validWords;

  const ReversalIsValidWordConstraint({required this.validWords})
      : super(
          id: 'reversal_is_valid_word',
          tier: 3,
          displayText: 'Spells a different word when reversed',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    final reversed = lower.split('').reversed.join();
    // Must be a different word (not a palindrome) and be valid
    return reversed != lower && validWords.contains(reversed);
  }
}

/// Word sounds like a number when spoken (homophones: won=one, too=two, for=four, ate=eight).
class HomophoneOfNumberConstraint extends Constraint {
  static const _numberHomophones = <String, String>{
    'won': 'one',
    'too': 'two',
    'for': 'four',
    'fore': 'four',
    'ate': 'eight',
    'six': 'six',
    'nein': 'nine',
  };

  const HomophoneOfNumberConstraint()
      : super(
          id: 'homophone_of_number',
          tier: 3,
          displayText: 'Sounds like a number',
        );

  @override
  bool validate(String word) =>
      _numberHomophones.containsKey(word.toLowerCase());
}

/// Word is an anagram of a specific target word.
class AnagramConstraint extends Constraint {
  final String targetWord;
  final String _sortedTarget;

  AnagramConstraint(this.targetWord)
      : _sortedTarget = _sortLetters(targetWord.toLowerCase()),
        super(
          id: 'anagram_of_$targetWord',
          tier: 3,
          displayText: 'An anagram of $targetWord',
        );

  static String _sortLetters(String s) {
    final chars = s.split('')..sort();
    return chars.join();
  }

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    // Must not be the same word
    if (lower == targetWord.toLowerCase()) return false;
    return _sortLetters(lower) == _sortedTarget;
  }
}

/// Build a set of common AnagramConstraints.
List<AnagramConstraint> buildAnagramConstraints() => [
      AnagramConstraint('least'),
      AnagramConstraint('stone'),
      AnagramConstraint('trace'),
      AnagramConstraint('angel'),
      AnagramConstraint('night'),
      AnagramConstraint('heart'),
      AnagramConstraint('earth'),
      AnagramConstraint('plate'),
    ];

/// Base Tier 3 constraints (excluding anagrams which are built dynamically).
final List<Constraint> tier3ConstraintsBase = [
  const PalindromeConstraint(),
  const HomophoneOfNumberConstraint(),
];
