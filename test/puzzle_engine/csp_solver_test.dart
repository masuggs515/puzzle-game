import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

/// A simple pass-through constraint that accepts every word.
class _AcceptAllConstraint extends Constraint {
  const _AcceptAllConstraint()
      : super(id: 'accept_all', tier: 1, displayText: 'Any word');

  @override
  bool validate(String word) => true;
}

void main() {
  setUp(() {
    CategoryListLoader.clearCache();
  });

  // Build a minimal constraint library for testing
  late ConstraintLibrary library;
  late CspSolver solver;

  setUp(() {
    library = ConstraintLibrary.build(validWords: {'cat', 'hat', 'bat', 'dog', 'log', 'bog'});
    solver = CspSolver(
      answerWords: ['cat', 'hat', 'bat', 'dog', 'log', 'bog', 'car', 'bar', 'tar'],
      constraintLibrary: library,
      seed: 42,
    );
  });

  group('CspSolver', () {
    test('solves a two-slot puzzle with one intersection', () {
      // Slot 0: any word (3 letters), Slot 1: any word (3 letters)
      // Intersection: slot 0 position 0 == slot 1 position 0 (same first letter)
      const acceptAll = _AcceptAllConstraint();
      final assignment = ConstraintAssignment(
        tier: 1,
        constraintId: 'accept_all',
        displayText: 'Any word',
        validator: acceptAll,
      );

      final skeleton = PuzzleSkeleton(
        slots: [
          SlotSpec(id: 0, constraint: assignment, requiredLength: 3),
          SlotSpec(id: 1, constraint: assignment, requiredLength: 3),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 0,
            positionInB: 0,
          ),
        ],
      );

      final puzzle = solver.solve(skeleton);
      expect(puzzle, isNotNull);
      expect(puzzle!.wordSlots.length, equals(2));

      // All slots assigned
      for (final slot in puzzle.wordSlots) {
        expect(slot.assignedWord, isNotNull);
      }

      // Intersection constraint satisfied: same character at position 0
      final wordA = puzzle.wordSlots[0].assignedWord!.toLowerCase();
      final wordB = puzzle.wordSlots[1].assignedWord!.toLowerCase();
      expect(wordA[0], equals(wordB[0]));

      // Words must be different
      expect(wordA, isNot(equals(wordB)));
    });

    test('same seed produces same result', () {
      const acceptAll = _AcceptAllConstraint();
      final assignment = ConstraintAssignment(
        tier: 1,
        constraintId: 'accept_all',
        displayText: 'Any word',
        validator: acceptAll,
      );

      final skeleton = PuzzleSkeleton(
        slots: [
          SlotSpec(id: 0, constraint: assignment, requiredLength: 3),
          SlotSpec(id: 1, constraint: assignment, requiredLength: 3),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 1,
            positionInB: 1,
          ),
        ],
      );

      final solver1 = CspSolver(
        answerWords: ['cat', 'hat', 'bat', 'car', 'bar'],
        constraintLibrary: library,
        seed: 99,
      );
      final solver2 = CspSolver(
        answerWords: ['cat', 'hat', 'bat', 'car', 'bar'],
        constraintLibrary: library,
        seed: 99,
      );

      final puzzle1 = solver1.solve(skeleton);
      final puzzle2 = solver2.solve(skeleton);

      expect(puzzle1, isNotNull);
      expect(puzzle2, isNotNull);
      expect(
        puzzle1!.wordSlots.map((s) => s.assignedWord).toList(),
        equals(puzzle2!.wordSlots.map((s) => s.assignedWord).toList()),
      );
    });

    test('different seeds can produce different results', () {
      const acceptAll = _AcceptAllConstraint();
      final assignment = ConstraintAssignment(
        tier: 1,
        constraintId: 'accept_all',
        displayText: 'Any word',
        validator: acceptAll,
      );

      final skeleton = PuzzleSkeleton(
        slots: [
          SlotSpec(id: 0, constraint: assignment, requiredLength: 3),
          SlotSpec(id: 1, constraint: assignment, requiredLength: 3),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 0,
            positionInB: 0,
          ),
        ],
      );

      final solverA = CspSolver(
        answerWords: ['cat', 'hat', 'bat', 'car', 'bar', 'dog', 'log', 'bog'],
        constraintLibrary: library,
        seed: 1,
      );
      final solverB = CspSolver(
        answerWords: ['cat', 'hat', 'bat', 'car', 'bar', 'dog', 'log', 'bog'],
        constraintLibrary: library,
        seed: 2,
      );

      final p1 = solverA.solve(skeleton);
      final p2 = solverB.solve(skeleton);

      // Both should be solvable — we just check they're not both null
      expect(p1 ?? p2, isNotNull);
    });

    test('returns null for impossible puzzle', () {
      // Slot 0 must contain 'x' at position 0, Slot 1 must contain 'y' at position 0
      // but the intersection forces them to share position 0 — impossible
      final xConstraint = ConstraintAssignment(
        tier: 4,
        constraintId: 'starts_with_x',
        displayText: 'Starts with X',
        validator: _StartsWithConstraint('x'),
      );
      final yConstraint = ConstraintAssignment(
        tier: 4,
        constraintId: 'starts_with_y',
        displayText: 'Starts with Y',
        validator: _StartsWithConstraint('y'),
      );

      final skeleton = PuzzleSkeleton(
        slots: [
          SlotSpec(id: 0, constraint: xConstraint, requiredLength: 3),
          SlotSpec(id: 1, constraint: yConstraint, requiredLength: 3),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 0,
            positionInB: 0,
          ),
        ],
      );

      // No words start with X in our tiny wordlist, so domain is empty
      final impossibleSolver = CspSolver(
        answerWords: ['cat', 'hat', 'bat'],
        constraintLibrary: library,
        seed: 42,
      );

      final result = impossibleSolver.solve(skeleton);
      expect(result, isNull);
    });
  });
}

class _StartsWithConstraint extends Constraint {
  final String _letter;

  _StartsWithConstraint(this._letter)
      : super(
          id: 'starts_with_$_letter',
          tier: 4,
          displayText: 'Starts with ${_letter.toUpperCase()}',
        );

  @override
  bool validate(String word) =>
      word.isNotEmpty && word[0].toLowerCase() == _letter;
}
