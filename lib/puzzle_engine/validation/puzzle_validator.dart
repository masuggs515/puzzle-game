import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

class ValidationResult {
  final bool isValid;
  final List<String> issues;

  const ValidationResult({
    required this.isValid,
    required this.issues,
  });

  @override
  String toString() =>
      isValid ? 'Valid' : 'Invalid: ${issues.join('; ')}';
}

class PuzzleValidator {
  final Set<String> answerWordSet;
  final Set<String> allValidWords;

  PuzzleValidator({
    required this.answerWordSet,
    required this.allValidWords,
  });

  /// Validate a fully-solved [Puzzle].
  ValidationResult validate(Puzzle puzzle) {
    final issues = <String>[];

    // 1. All slots must have an assigned word
    for (final slot in puzzle.wordSlots) {
      if (slot.assignedWord == null || slot.assignedWord!.isEmpty) {
        issues.add('Slot ${slot.id} has no assigned word');
      }
    }
    if (issues.isNotEmpty) return ValidationResult(isValid: false, issues: issues);

    // 2. All assigned words must be in the answer word set
    for (final slot in puzzle.wordSlots) {
      final word = slot.assignedWord!.toLowerCase();
      if (!answerWordSet.contains(word)) {
        issues.add('Word "$word" in slot ${slot.id} is not in the answer word list');
      }
    }

    // 3. All assigned words must satisfy their slot's constraint
    for (final slot in puzzle.wordSlots) {
      final word = slot.assignedWord!.toLowerCase();
      if (!slot.constraint.validator.validate(word)) {
        issues.add(
          'Word "$word" in slot ${slot.id} does not satisfy constraint '
          '"${slot.constraint.constraintId}"',
        );
      }
    }

    // 4. Word lengths must match required lengths
    for (final slot in puzzle.wordSlots) {
      if (slot.requiredLength != null) {
        final word = slot.assignedWord!;
        if (word.length != slot.requiredLength) {
          issues.add(
            'Word "$word" in slot ${slot.id} has length ${word.length}, '
            'expected ${slot.requiredLength}',
          );
        }
      }
    }

    // 5. No word is assigned to more than one slot
    final words = puzzle.wordSlots.map((s) => s.assignedWord!.toLowerCase()).toList();
    final unique = words.toSet();
    if (unique.length != words.length) {
      issues.add('Duplicate words found across slots');
    }

    // 6. All intersections must have matching letters
    for (final intersection in puzzle.intersections) {
      final slotA = puzzle.wordSlots
          .firstWhere((s) => s.id == intersection.slotAId);
      final slotB = puzzle.wordSlots
          .firstWhere((s) => s.id == intersection.slotBId);

      final wordA = slotA.assignedWord!.toLowerCase();
      final wordB = slotB.assignedWord!.toLowerCase();

      if (intersection.positionInA >= wordA.length) {
        issues.add(
          'Intersection positionInA=${intersection.positionInA} out of bounds '
          'for word "$wordA" in slot ${slotA.id}',
        );
        continue;
      }
      if (intersection.positionInB >= wordB.length) {
        issues.add(
          'Intersection positionInB=${intersection.positionInB} out of bounds '
          'for word "$wordB" in slot ${slotB.id}',
        );
        continue;
      }

      final charA = wordA[intersection.positionInA];
      final charB = wordB[intersection.positionInB];
      if (charA != charB) {
        issues.add(
          'Intersection mismatch: slot ${slotA.id} word "$wordA" '
          'at pos ${intersection.positionInA} is "$charA", '
          'but slot ${slotB.id} word "$wordB" '
          'at pos ${intersection.positionInB} is "$charB"',
        );
      }
    }

    // 7. Letter pool must contain all letters needed for the solution
    final requiredLetters = puzzle.wordSlots
        .expand((s) => s.assignedWord!.toLowerCase().split(''))
        .toSet();
    final poolSet = puzzle.letterPool.map((l) => l.toLowerCase()).toSet();
    for (final letter in requiredLetters) {
      if (!poolSet.contains(letter)) {
        issues.add('Letter "$letter" needed for solution but missing from letter pool');
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }
}
