import 'dart:math';

import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/generation/difficulty_profile.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';

class PreGenerator {
  final CspSolver solver;
  final PuzzleValidator validator;
  final ConstraintLibrary constraintLibrary;

  PreGenerator({
    required this.solver,
    required this.validator,
    required this.constraintLibrary,
  });

  /// Generate a single puzzle matching the given [difficulty] profile.
  /// Returns null if no valid puzzle can be generated.
  Puzzle? generate(DifficultyProfile difficulty, {required int seed}) {
    final rng = Random(seed);

    // Select random constraints from allowed tiers
    final selectedConstraints = _selectConstraints(difficulty, rng);
    if (selectedConstraints == null) return null;

    // Build slot specs from selected constraints
    final slotSpecs = selectedConstraints
        .map((c) => (c.id, null as int?))
        .toList();

    // Number of word slots = intersections + 1 (for a simple chain)
    final intersectionSpecs = _buildIntersectionPattern(
      slotCount: slotSpecs.length,
      intersectionCount: difficulty.intersectionCount,
      rng: rng,
    );

    // Build skeleton and solve
    try {
      final skeleton = _buildSkeleton(slotSpecs, intersectionSpecs);
      final puzzleSolver = CspSolver(
        answerWords: solver.answerWords,
        constraintLibrary: constraintLibrary,
        seed: seed,
      );
      final puzzle = puzzleSolver.solve(skeleton);
      if (puzzle == null) return null;

      return _withMetadata(puzzle, difficulty, seed);
    } catch (e) {
      return null;
    }
  }

  List<Constraint>? _selectConstraints(DifficultyProfile difficulty, Random rng) {
    final available = difficulty.allowedConstraintTiers
        .expand((t) => constraintLibrary.forTier(t))
        .toList();

    if (available.isEmpty) return null;

    // Word count = intersections + 1 (for a simple chain topology)
    final wordCount = difficulty.intersectionCount + 1;
    if (available.length < wordCount) return null;

    available.shuffle(rng);
    return available.take(wordCount).toList();
  }

  List<(int, int, int, int)> _buildIntersectionPattern({
    required int slotCount,
    required int intersectionCount,
    required Random rng,
  }) {
    final specs = <(int, int, int, int)>[];

    // Build a simple chain: slot 0↔1, 1↔2, 2↔3, etc.
    for (int i = 0; i < slotCount - 1 && specs.length < intersectionCount; i++) {
      final posA = rng.nextInt(4); // position 0–3 (safe for 4+ letter words)
      final posB = rng.nextInt(4);
      specs.add((i, posA, i + 1, posB));
    }

    return specs;
  }

  PuzzleSkeleton _buildSkeleton(
    List<(String, int?)> slotSpecs,
    List<(int, int, int, int)> intersectionSpecs,
  ) {
    final slots = <SlotSpec>[];
    for (int index = 0; index < slotSpecs.length; index++) {
      final (constraintId, requiredLength) = slotSpecs[index];
      final constraint = constraintLibrary.getById(constraintId);
      if (constraint == null) {
        throw ArgumentError('Unknown constraint: $constraintId');
      }
      slots.add(SlotSpec(
        id: index,
        constraint: ConstraintAssignment(
          tier: constraint.tier,
          constraintId: constraintId,
          displayText: constraint.displayText,
          validator: constraint,
        ),
        requiredLength: requiredLength,
      ));
    }

    final intersections = intersectionSpecs.map((spec) {
      final (slotA, posA, slotB, posB) = spec;
      return Intersection(
        slotAId: slotA,
        slotBId: slotB,
        positionInA: posA,
        positionInB: posB,
      );
    }).toList();

    return PuzzleSkeleton(slots: slots, intersections: intersections);
  }

  Puzzle _withMetadata(Puzzle puzzle, DifficultyProfile difficulty, int seed) {
    return Puzzle(
      seed: seed.toString(),
      levelNumber: difficulty.levelNumber,
      levelType: difficulty.levelType,
      isBoss: difficulty.isBoss,
      wordSlots: puzzle.wordSlots,
      intersections: puzzle.intersections,
      letterPool: _buildLetterPool(puzzle),
      constraintTiers: difficulty.allowedConstraintTiers,
      metadata: {
        'generated_at': DateTime.now().toIso8601String(),
        'seed': seed,
        'intersection_count': difficulty.intersectionCount,
      },
    );
  }

  List<String> _buildLetterPool(Puzzle puzzle) {
    final letters = puzzle.wordSlots
        .where((s) => s.assignedWord != null)
        .expand((s) => s.assignedWord!.toLowerCase().split(''))
        .toSet()
        .toList()
      ..sort();
    return letters;
  }
}
