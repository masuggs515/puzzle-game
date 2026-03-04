import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';

/// Combines two constraints — the word must satisfy both.
class CombinedConstraint extends Constraint {
  final Constraint constraintA;
  final Constraint constraintB;

  CombinedConstraint({
    required this.constraintA,
    required this.constraintB,
    required super.id,
    required super.displayText,
  }) : super(tier: 5);

  @override
  bool validate(String word) =>
      constraintA.validate(word) && constraintB.validate(word);

  @override
  List<String> filterWordList(List<String> words) {
    // Two-pass filter is more efficient than super.filterWordList
    return constraintB.filterWordList(constraintA.filterWordList(words));
  }
}

/// Word is a compound word — formed from two complete words both in the valid set.
class IsCompoundWordConstraint extends Constraint {
  final Set<String> validWords;

  const IsCompoundWordConstraint({required this.validWords})
      : super(
          id: 'is_compound_word',
          tier: 5,
          displayText: 'Is a compound word',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    if (lower.length < 4) return false;
    // Try every split point
    for (int i = 2; i <= lower.length - 2; i++) {
      final part1 = lower.substring(0, i);
      final part2 = lower.substring(i);
      if (validWords.contains(part1) && validWords.contains(part2)) {
        return true;
      }
    }
    return false;
  }
}

/// Build all Tier 5 combined constraints from a pair of lower-tier constraints.
List<CombinedConstraint> buildTier5Constraints(List<Constraint> lowerTierConstraints) {
  final result = <CombinedConstraint>[];

  // Predefined meaningful combinations
  const combinations = [
    ('is_animal', 'no_repeated_letters', 'animal_no_repeat', 'An animal with all unique letters'),
    ('is_color', 'palindrome', 'color_palindrome', 'A color that reads the same backwards'),
    ('is_food', 'has_double_letter', 'food_double_letter', 'A food with a double letter'),
    ('is_animal', 'starts_with_vowel', 'animal_starts_vowel', 'An animal starting with a vowel'),
    ('is_clothing', 'has_double_letter', 'clothing_double_letter', 'Clothing with a double letter'),
    ('is_body_part', 'no_repeated_letters', 'body_part_no_repeat', 'A body part with all unique letters'),
    ('is_sport', 'ends_with_vowel', 'sport_ends_vowel', 'A sport ending with a vowel'),
    ('is_weather', 'same_first_last', 'weather_same_first_last', 'A weather word with matching first and last letters'),
  ];

  final byId = {for (final c in lowerTierConstraints) c.id: c};

  for (final (aId, bId, combinedId, text) in combinations) {
    final a = byId[aId];
    final b = byId[bId];
    if (a != null && b != null) {
      result.add(CombinedConstraint(
        constraintA: a,
        constraintB: b,
        id: combinedId,
        displayText: text,
      ));
    }
  }

  return result;
}
