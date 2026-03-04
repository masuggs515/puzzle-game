import 'dart:math';

import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/solver/intersection_structure.dart';

/// Higher-level orchestrator that combines the CSP solver and skeleton builder.
class PuzzleBuilder {
  final List<String> answerWords;
  final ConstraintLibrary library;
  final int? _seed;

  PuzzleBuilder({
    required this.answerWords,
    required this.library,
    int? seed,
  }) : _seed = seed;

  /// Build a puzzle with the given constraints and intersection structure.
  ///
  /// Returns a solved [Puzzle] or null if the solver could not find a solution.
  Puzzle? build({
    required List<(String constraintId, int? requiredLength)> slotSpecs,
    required List<(int slotA, int posA, int slotB, int posB)> intersectionSpecs,
    int? seed,
  }) {
    final effectiveSeed = seed ?? _seed ?? Random().nextInt(0x7FFFFFFF);
    final solver = CspSolver(
      answerWords: answerWords,
      constraintLibrary: library,
      seed: effectiveSeed,
    );
    final skeleton = IntersectionStructureBuilder.build(
      slotSpecs: slotSpecs,
      intersectionSpecs: intersectionSpecs,
      library: library,
    );
    return solver.solve(skeleton);
  }
}
