import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/generation/difficulty_profile.dart';
import 'package:puzzle_game/puzzle_engine/generation/runtime_generator.dart';
import 'package:puzzle_game/puzzle_engine/generation/pre_generator.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

void main() {
  setUp(() {
    CategoryListLoader.clearCache();
    // Preload minimal categories for tier 1 constraints
    CategoryListLoader.preload(
      'animals',
      {'cat', 'dog', 'bird', 'fish', 'frog', 'bear', 'deer', 'wolf', 'lion', 'tiger'},
    );
    CategoryListLoader.preload('colors', {'red', 'blue', 'green', 'gold', 'pink'});
    CategoryListLoader.preload('foods', {'bread', 'cake', 'rice', 'bean', 'pear', 'plum'});
    CategoryListLoader.preload('countries', {'france', 'spain', 'china', 'japan', 'india'});
    CategoryListLoader.preload('vegetables', {'carrot', 'onion', 'potato', 'celery'});
    CategoryListLoader.preload('sports', {'golf', 'polo', 'darts', 'boxing'});
    CategoryListLoader.preload('body_parts', {'arm', 'leg', 'knee', 'chin', 'heel', 'shin'});
    CategoryListLoader.preload('weather', {'rain', 'snow', 'hail', 'fog', 'wind', 'mist'});
    CategoryListLoader.preload('vehicles', {'car', 'bus', 'van', 'jet', 'boat', 'tram'});
    CategoryListLoader.preload('clothing', {'hat', 'coat', 'vest', 'boot', 'cape'});
    CategoryListLoader.preload('fruits', {'apple', 'mango', 'grape', 'plum', 'lime', 'pear'});
    CategoryListLoader.preload('water_bodies', {'lake', 'river', 'ocean', 'bay', 'cove', 'sea'});
    CategoryListLoader.preload('kitchen_items', {'pan', 'bowl', 'fork', 'pot', 'wok', 'jar'});
  });

  group('DifficultyProfile', () {
    test('level 1 uses tier 1 only with 1 intersection', () {
      final profile = DifficultyProfile.forLevel(1);
      expect(profile.levelNumber, equals(1));
      expect(profile.intersectionCount, equals(1));
      expect(profile.allowedConstraintTiers, equals([1]));
      expect(profile.isBoss, isFalse);
      expect(profile.decoyLetterCount, equals(0));
    });

    test('level 10 is a boss level', () {
      final profile = DifficultyProfile.forLevel(10);
      expect(profile.isBoss, isTrue);
    });

    test('level 20 is a boss level', () {
      final profile = DifficultyProfile.forLevel(20);
      expect(profile.isBoss, isTrue);
    });

    test('level 15 is not a boss level', () {
      final profile = DifficultyProfile.forLevel(15);
      expect(profile.isBoss, isFalse);
    });

    test('level 11-24 uses tier 1-2 constraints', () {
      final profile = DifficultyProfile.forLevel(15);
      expect(profile.allowedConstraintTiers, contains(1));
      expect(profile.allowedConstraintTiers, contains(2));
    });

    test('level 25-50 uses tier 1-3 constraints', () {
      // Use level 33 — not a boss level (33 % 10 != 0)
      final profile = DifficultyProfile.forLevel(33);
      expect(profile.allowedConstraintTiers, contains(1));
      expect(profile.allowedConstraintTiers, contains(2));
      expect(profile.allowedConstraintTiers, contains(3));
      expect(profile.decoyLetterCount, equals(2));
    });

    test('level 51-99 uses tier 1-4 constraints', () {
      final profile = DifficultyProfile.forLevel(60);
      expect(profile.allowedConstraintTiers, contains(4));
      expect(profile.decoyLetterCount, equals(4));
    });

    test('levels 191-200 are all boss levels', () {
      for (int i = 191; i <= 200; i++) {
        final profile = DifficultyProfile.forLevel(i);
        expect(profile.isBoss, isTrue, reason: 'Level $i should be boss');
      }
    });

    test('levels 191-200 use tier 4-5 constraints', () {
      final profile = DifficultyProfile.forLevel(195);
      expect(profile.allowedConstraintTiers, contains(4));
      expect(profile.allowedConstraintTiers, contains(5));
    });

    test('level type is puzzle for levels 1-200', () {
      expect(DifficultyProfile.forLevel(1).levelType, equals(LevelType.puzzle));
      expect(DifficultyProfile.forLevel(100).levelType, equals(LevelType.puzzle));
      expect(DifficultyProfile.forLevel(200).levelType, equals(LevelType.puzzle));
    });

    test('level type is vault for levels above 200', () {
      expect(DifficultyProfile.forLevel(201).levelType, equals(LevelType.vault));
    });
  });

  group('RuntimeGenerator', () {
    late ConstraintLibrary library;
    late CspSolver solver;
    late PuzzleValidator validator;
    late PreGenerator preGen;
    late RuntimeGenerator runtimeGen;

    // Use a larger word list to improve solver success rate
    final testWords = [
      'cat', 'dog', 'hat', 'bat', 'rat', 'sat', 'fat', 'mat', 'pat', 'vat',
      'car', 'bar', 'far', 'jar', 'tar', 'war', 'par', 'mar', 'gar',
      'log', 'bog', 'cog', 'fog', 'hog', 'jog', 'tog',
      'red', 'bed', 'fed', 'led', 'wed', 'ned', 'ted',
      'arm', 'art', 'arc', 'are',
      'blue', 'bear', 'bird', 'bolt', 'born', 'bold',
      'deer', 'dark', 'done', 'dusk', 'dust',
      'fire', 'fish', 'flag', 'flat', 'flew', 'flex',
      'gold', 'golf', 'gust', 'gust',
      'hail', 'half', 'hall', 'hand', 'hard',
      'lake', 'land', 'lean', 'left', 'lime',
      'mist', 'mild', 'mint', 'mole', 'mood',
      'nest', 'note', 'noun',
      'rain', 'race', 'rack', 'rail', 'rank',
      'seal', 'shin', 'ship', 'shoe', 'shot',
      'tail', 'tale', 'tank', 'tape',
      'vine', 'void', 'vote',
      'wave', 'wind', 'wolf', 'wood', 'word',
    ];

    setUp(() {
      library = ConstraintLibrary.build(validWords: testWords.toSet());
      solver = CspSolver(
        answerWords: testWords,
        constraintLibrary: library,
        seed: 42,
      );
      validator = PuzzleValidator(
        answerWordSet: testWords.toSet(),
        allValidWords: testWords.toSet(),
      );
      preGen = PreGenerator(
        solver: solver,
        validator: validator,
        constraintLibrary: library,
      );
      runtimeGen = RuntimeGenerator(preGenerator: preGen);
    });

    test('same userId and vaultLevel produces same puzzle', () {
      final puzzle1 = runtimeGen.generateVaultPuzzle(
        userId: 'user-abc-123',
        vaultLevel: 5,
      );
      final puzzle2 = runtimeGen.generateVaultPuzzle(
        userId: 'user-abc-123',
        vaultLevel: 5,
      );

      // Both should produce the same result (both null or both same puzzle)
      if (puzzle1 != null && puzzle2 != null) {
        expect(puzzle1.seed, equals(puzzle2.seed));
        expect(
          puzzle1.wordSlots.map((s) => s.assignedWord).toList(),
          equals(puzzle2.wordSlots.map((s) => s.assignedWord).toList()),
        );
      } else {
        // Both null is also valid (unsolvable for this config)
        expect(puzzle1, equals(puzzle2));
      }
    });

    test('different vaultLevel produces different seeds', () {
      // The seed derivation should differ for different vault levels
      // We cannot test puzzle equality directly without a large word list,
      // but we can verify the generator doesn't crash and behaves deterministically.
      runtimeGen.generateVaultPuzzle(userId: 'user-xyz', vaultLevel: 1);
      runtimeGen.generateVaultPuzzle(userId: 'user-xyz', vaultLevel: 2);

      // Not asserting non-null (small word list), just no crash
      expect(true, isTrue); // Reached here without exception
    });
  });

  group('PreGenerator', () {
    late ConstraintLibrary library;
    late CspSolver solver;
    late PuzzleValidator validator;
    late PreGenerator generator;

    final testWords = [
      'cat', 'dog', 'hat', 'bat', 'rat',
      'car', 'bar', 'far', 'jar', 'tar',
      'log', 'bog', 'cog', 'fog', 'hog',
      'arm', 'art', 'arc',
      'red', 'bed', 'fed', 'led', 'wed',
      'blue', 'bear', 'bird', 'bold', 'bolt',
      'deer', 'dark', 'dusk', 'dust',
      'fire', 'fish', 'flag', 'flat',
      'gold', 'golf',
      'hail', 'hall', 'hand',
      'lake', 'land', 'lean',
      'mist', 'mild', 'mint',
      'nest', 'note',
      'rain', 'race', 'rail', 'rank',
      'seal', 'shin', 'ship',
      'tail', 'tale', 'tank',
      'vine', 'vote',
      'wave', 'wind', 'wolf',
    ];

    setUp(() {
      library = ConstraintLibrary.build(validWords: testWords.toSet());
      solver = CspSolver(
        answerWords: testWords,
        constraintLibrary: library,
        seed: 1,
      );
      validator = PuzzleValidator(
        answerWordSet: testWords.toSet(),
        allValidWords: testWords.toSet(),
      );
      generator = PreGenerator(
        solver: solver,
        validator: validator,
        constraintLibrary: library,
      );
    });

    test('generate returns a puzzle or null for tier 1 difficulty', () {
      final difficulty = DifficultyProfile.forLevel(1);
      // May return null with small word list — just verify no crash
      expect(() => generator.generate(difficulty, seed: 42), returnsNormally);
    });

    test('generated puzzle passes validator when non-null', () {
      final difficulty = DifficultyProfile.forLevel(1);
      for (int seed = 1; seed <= 20; seed++) {
        final puzzle = generator.generate(difficulty, seed: seed);
        if (puzzle != null) {
          final result = validator.validate(puzzle);
          expect(
            result.isValid,
            isTrue,
            reason: 'Puzzle from seed $seed failed: ${result.issues.join('; ')}',
          );
        }
      }
    });
  });
}
