import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

/// Builds a [PuzzleSkeleton] given slot and intersection specifications.
class IntersectionStructureBuilder {
  /// Build a skeleton with the given structure.
  ///
  /// [slotSpecs] is a list of (constraintId, optionalRequiredLength?) tuples.
  /// [intersectionSpecs] is a list of (slotAIndex, posInA, slotBIndex, posInB) tuples.
  static PuzzleSkeleton build({
    required List<(String constraintId, int? requiredLength)> slotSpecs,
    required List<(int slotA, int posA, int slotB, int posB)> intersectionSpecs,
    required ConstraintLibrary library,
  }) {
    final slots = <SlotSpec>[];
    for (int index = 0; index < slotSpecs.length; index++) {
      final (constraintId, requiredLength) = slotSpecs[index];
      final constraint = library.getById(constraintId);
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
}
