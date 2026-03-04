import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';

enum LevelType { sprint, puzzle, vault }

class WordSlot {
  final int id;
  final ConstraintAssignment constraint;
  final int? requiredLength;
  String? assignedWord;

  WordSlot({
    required this.id,
    required this.constraint,
    this.requiredLength,
    this.assignedWord,
  });

  WordSlot copyWith({String? assignedWord}) => WordSlot(
    id: id,
    constraint: constraint,
    requiredLength: requiredLength,
    assignedWord: assignedWord ?? this.assignedWord,
  );
}

class Intersection {
  final int slotAId;
  final int slotBId;
  final int positionInA;
  final int positionInB;

  const Intersection({
    required this.slotAId,
    required this.slotBId,
    required this.positionInA,
    required this.positionInB,
  });
}

class Puzzle {
  final String seed;
  final int? levelNumber;
  final LevelType levelType;
  final bool isBoss;
  final List<WordSlot> wordSlots;
  final List<Intersection> intersections;
  final List<String> letterPool;
  final List<int> constraintTiers;
  final Map<String, dynamic> metadata;

  Puzzle({
    required this.seed,
    this.levelNumber,
    required this.levelType,
    required this.isBoss,
    required this.wordSlots,
    required this.intersections,
    required this.letterPool,
    required this.constraintTiers,
    required this.metadata,
  });

  int get wordCount => wordSlots.length;
  int get intersectionCount => intersections.length;
  bool get isSolved => wordSlots.every((s) => s.assignedWord != null);
}

// A skeleton before words are assigned — used by CSP solver
class PuzzleSkeleton {
  final List<SlotSpec> slots;
  final List<Intersection> intersections;

  PuzzleSkeleton({required this.slots, required this.intersections});
}

class SlotSpec {
  final int id;
  final ConstraintAssignment constraint;
  final int? requiredLength;

  SlotSpec({required this.id, required this.constraint, this.requiredLength});
}
