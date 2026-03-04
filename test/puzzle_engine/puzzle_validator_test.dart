import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';

class _AcceptAllConstraint extends Constraint {
  const _AcceptAllConstraint()
      : super(id: 'accept_all', tier: 1, displayText: 'Any word');

  @override
  bool validate(String word) => true;
}

class _AnimalsConstraint extends Constraint {
  final Set<String> _animals;

  _AnimalsConstraint(this._animals)
      : super(id: 'is_animal', tier: 1, displayText: 'An animal');

  @override
  bool validate(String word) => _animals.contains(word.toLowerCase());
}

ConstraintAssignment _acceptAllAssignment() => ConstraintAssignment(
      tier: 1,
      constraintId: 'accept_all',
      displayText: 'Any word',
      validator: const _AcceptAllConstraint(),
    );

void main() {
  final answerWords = {'cat', 'dog', 'hat', 'log'};
  final allValidWords = {'cat', 'dog', 'hat', 'log', 'cats', 'dogs'};

  late PuzzleValidator validator;

  setUp(() {
    validator = PuzzleValidator(
      answerWordSet: answerWords,
      allValidWords: allValidWords,
    );
  });

  group('PuzzleValidator', () {
    test('valid puzzle passes validation', () {
      // cat[1]='a', car[1]='a' — match at position 1
      final puzzleFixed = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            requiredLength: 3,
            assignedWord: 'cat',
          ),
          WordSlot(
            id: 1,
            constraint: _acceptAllAssignment(),
            requiredLength: 3,
            assignedWord: 'hat',
          ),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 2,
            positionInB: 2,
          ),
        ],
        // cat[2]='t', hat[2]='t' — match!
        letterPool: ['a', 'c', 'h', 't'],
        constraintTiers: [1],
        metadata: {},
      );

      // Add hat to answer words for this test
      final validatorWithHat = PuzzleValidator(
        answerWordSet: {'cat', 'hat', 'dog', 'log'},
        allValidWords: allValidWords,
      );
      final result = validatorWithHat.validate(puzzleFixed);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('puzzle with unassigned word fails', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            assignedWord: null, // unassigned
          ),
        ],
        intersections: [],
        letterPool: [],
        constraintTiers: [1],
        metadata: {},
      );

      final result = validator.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(result.issues, isNotEmpty);
    });

    test('puzzle with word not in answer list fails', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            assignedWord: 'xenon', // not in answerWords
          ),
        ],
        intersections: [],
        letterPool: ['e', 'n', 'o', 'x'],
        constraintTiers: [1],
        metadata: {},
      );

      final result = validator.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('not in the answer word list')), isTrue);
    });

    test('puzzle with constraint violation fails', () {
      final animalConstraint = ConstraintAssignment(
        tier: 1,
        constraintId: 'is_animal',
        displayText: 'An animal',
        validator: _AnimalsConstraint({'dog', 'cat'}),
      );

      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: animalConstraint,
            assignedWord: 'hat', // not an animal
          ),
        ],
        intersections: [],
        letterPool: ['a', 'h', 't'],
        constraintTiers: [1],
        metadata: {},
      );

      final validatorWithHat = PuzzleValidator(
        answerWordSet: {'cat', 'hat', 'dog'},
        allValidWords: allValidWords,
      );
      final result = validatorWithHat.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('does not satisfy constraint')), isTrue);
    });

    test('puzzle with intersection mismatch fails', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            assignedWord: 'cat',
          ),
          WordSlot(
            id: 1,
            constraint: _acceptAllAssignment(),
            assignedWord: 'dog',
          ),
        ],
        intersections: [
          const Intersection(
            slotAId: 0,
            slotBId: 1,
            positionInA: 0, // cat[0] = 'c'
            positionInB: 0, // dog[0] = 'd'  -- MISMATCH
          ),
        ],
        letterPool: ['a', 'c', 'd', 'g', 'o', 't'],
        constraintTiers: [1],
        metadata: {},
      );

      final result = validator.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('mismatch')), isTrue);
    });

    test('puzzle with duplicate words fails', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            assignedWord: 'cat',
          ),
          WordSlot(
            id: 1,
            constraint: _acceptAllAssignment(),
            assignedWord: 'cat', // duplicate
          ),
        ],
        intersections: [],
        letterPool: ['a', 'c', 't'],
        constraintTiers: [1],
        metadata: {},
      );

      final result = validator.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('Duplicate')), isTrue);
    });

    test('puzzle with missing letter in pool fails', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.puzzle,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _acceptAllAssignment(),
            assignedWord: 'cat',
          ),
        ],
        intersections: [],
        letterPool: ['c', 'a'], // missing 't'
        constraintTiers: [1],
        metadata: {},
      );

      final result = validator.validate(puzzle);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.contains('missing from letter pool')),
        isTrue,
      );
    });
  });
}
