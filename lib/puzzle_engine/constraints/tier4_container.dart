import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

/// Removing the first letter leaves a valid English word.
class RemoveFirstLetterIsValidConstraint extends Constraint {
  final Set<String> validWords;

  const RemoveFirstLetterIsValidConstraint({required this.validWords})
      : super(
          id: 'remove_first_letter_is_valid',
          tier: 4,
          displayText: 'Remove the first letter to get a new word',
        );

  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    final trimmed = word.substring(1).toLowerCase();
    return validWords.contains(trimmed);
  }
}

/// Removing the last letter leaves a valid English word.
class RemoveLastLetterIsValidConstraint extends Constraint {
  final Set<String> validWords;

  const RemoveLastLetterIsValidConstraint({required this.validWords})
      : super(
          id: 'remove_last_letter_is_valid',
          tier: 4,
          displayText: 'Remove the last letter to get a new word',
        );

  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    final trimmed = word.substring(0, word.length - 1).toLowerCase();
    return validWords.contains(trimmed);
  }
}

/// Word contains a hidden shorter word (at least 3 chars) somewhere inside it
/// (not at start or end — truly hidden).
class ContainsHiddenWordConstraint extends Constraint {
  final Set<String> validWords;
  final int minHiddenLength;

  ContainsHiddenWordConstraint({
    required this.validWords,
    this.minHiddenLength = 3,
  }) : super(
          id: 'contains_hidden_word',
          tier: 4,
          displayText: 'Contains a hidden word inside it',
        );

  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    if (lower.length < minHiddenLength + 2) return false;
    // Check all substrings of length >= minHiddenLength that are strictly interior
    for (int start = 1; start < lower.length - minHiddenLength; start++) {
      for (int end = start + minHiddenLength; end < lower.length; end++) {
        final sub = lower.substring(start, end);
        if (validWords.contains(sub)) return true;
      }
    }
    return false;
  }
}

/// Adding one letter (anywhere) can form a water body name.
class AddOneLetterIsWaterBodyConstraint extends Constraint {
  AddOneLetterIsWaterBodyConstraint()
      : super(
          id: 'add_letter_is_water_body',
          tier: 4,
          displayText: 'Add one letter to make a body of water',
        );

  @override
  bool validate(String word) {
    final waterBodies = CategoryListLoader.get('water_bodies');
    final lower = word.toLowerCase();
    for (final body in waterBodies) {
      if (body.length == lower.length + 1) {
        // Check if lower is a subsequence or near-match (one insertion)
        if (_canInsertOneChar(lower, body)) return true;
      }
    }
    return false;
  }

  /// Returns true if [target] can be formed by inserting exactly one character into [source].
  bool _canInsertOneChar(String source, String target) {
    if (target.length != source.length + 1) return false;
    int i = 0;
    int j = 0;
    int diff = 0;
    while (i < source.length && j < target.length) {
      if (source[i] == target[j]) {
        i++;
        j++;
      } else {
        diff++;
        j++;
        if (diff > 1) return false;
      }
    }
    return true;
  }
}

/// Starts with a specific letter.
class StartsWithLetterConstraint extends Constraint {
  final String letter;

  StartsWithLetterConstraint(String letter)
      : letter = letter.toLowerCase(),
        super(
          id: 'starts_with_${letter.toLowerCase()}',
          tier: 4,
          displayText: 'Starts with the letter ${letter.toUpperCase()}',
        );

  @override
  bool validate(String word) {
    if (word.isEmpty) return false;
    return word[0].toLowerCase() == letter;
  }
}

/// Ends with a specific letter.
class EndsWithLetterConstraint extends Constraint {
  final String letter;

  EndsWithLetterConstraint(String letter)
      : letter = letter.toLowerCase(),
        super(
          id: 'ends_with_${letter.toLowerCase()}',
          tier: 4,
          displayText: 'Ends with the letter ${letter.toUpperCase()}',
        );

  @override
  bool validate(String word) {
    if (word.isEmpty) return false;
    return word[word.length - 1].toLowerCase() == letter;
  }
}

/// Contains a specific letter somewhere in the word.
class ContainsLetterConstraint extends Constraint {
  final String letter;

  ContainsLetterConstraint(String letter)
      : letter = letter.toLowerCase(),
        super(
          id: 'contains_letter_${letter.toLowerCase()}',
          tier: 4,
          displayText: 'Contains the letter ${letter.toUpperCase()}',
        );

  @override
  bool validate(String word) => word.toLowerCase().contains(letter);
}

/// A specific position (0-indexed) in the word must be a given letter.
class LetterAtPositionConstraint extends Constraint {
  final int position;
  final String letter;

  LetterAtPositionConstraint(this.position, String letter)
      : letter = letter.toLowerCase(),
        super(
          id: 'letter_at_position_${position}_is_${letter.toLowerCase()}',
          tier: 4,
          displayText:
              'Letter ${position + 1} is ${letter.toUpperCase()}',
        );

  @override
  bool validate(String word) {
    if (word.length <= position) return false;
    return word[position].toLowerCase() == letter;
  }
}
