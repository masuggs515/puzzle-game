import 'dart:convert';

import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

/// A no-op constraint used when deserializing an unknown constraint ID.
class _PassThroughConstraint extends Constraint {
  const _PassThroughConstraint({
    required super.id,
    required super.tier,
    required super.displayText,
  });

  @override
  bool validate(String word) => true;
}

class PuzzleSerializer {
  final ConstraintLibrary library;

  PuzzleSerializer({required this.library});

  /// Serialize a [Puzzle] to a JSON-compatible map.
  Map<String, dynamic> toJson(Puzzle puzzle) {
    return {
      'seed': puzzle.seed,
      'level_number': puzzle.levelNumber,
      'level_type': puzzle.levelType.name,
      'is_boss': puzzle.isBoss,
      'word_slots': puzzle.wordSlots.map((slot) => {
            'id': slot.id,
            'constraint_id': slot.constraint.constraintId,
            'constraint_tier': slot.constraint.tier,
            'constraint_display': slot.constraint.displayText,
            'required_length': slot.requiredLength,
            'assigned_word': slot.assignedWord,
          }).toList(),
      'intersections': puzzle.intersections.map((i) => {
            'slot_a': i.slotAId,
            'slot_b': i.slotBId,
            'position_in_a': i.positionInA,
            'position_in_b': i.positionInB,
          }).toList(),
      'letter_pool': puzzle.letterPool,
      'constraint_tiers': puzzle.constraintTiers,
      'metadata': puzzle.metadata,
    };
  }

  /// Serialize a [Puzzle] to a JSON string.
  String toJsonString(Puzzle puzzle) =>
      const JsonEncoder.withIndent('  ').convert(toJson(puzzle));

  /// Safely cast a dynamic value to a typed String-keyed map.
  static Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  /// Deserialize a [Puzzle] from a JSON-compatible map.
  Puzzle fromJson(Map<String, dynamic> json) {
    final levelTypeStr = json['level_type'] as String? ?? 'sprint';
    final levelType = LevelType.values.firstWhere(
      (t) => t.name == levelTypeStr,
      orElse: () => LevelType.sprint,
    );

    final wordSlots = (json['word_slots'] as List<dynamic>).map((slotJson) {
      final map = _toStringDynamicMap(slotJson);
      final constraintId = map['constraint_id'] as String;
      final tier = map['constraint_tier'] as int;
      final displayText = (map['constraint_display'] ?? map['display_text']) as String;

      final constraintInstance = library.getById(constraintId) ??
          _PassThroughConstraint(
            id: constraintId,
            tier: tier,
            displayText: displayText,
          );

      return WordSlot(
        id: map['id'] as int,
        constraint: ConstraintAssignment(
          tier: tier,
          constraintId: constraintId,
          displayText: displayText,
          validator: constraintInstance,
        ),
        requiredLength: map['required_length'] as int?,
        assignedWord: map['assigned_word'] as String?,
      );
    }).toList();

    final intersections =
        (json['intersections'] as List<dynamic>).map((iJson) {
      final map = _toStringDynamicMap(iJson);
      return Intersection(
        slotAId: (map['slot_a'] ?? map['slot_a_id']) as int,
        slotBId: (map['slot_b'] ?? map['slot_b_id']) as int,
        positionInA: map['position_in_a'] as int,
        positionInB: map['position_in_b'] as int,
      );
    }).toList();

    final letterPool = (json['letter_pool'] as List<dynamic>)
        .map((e) => e as String)
        .toList();

    final constraintTiers = (json['constraint_tiers'] as List<dynamic>)
        .map((e) => e as int)
        .toList();

    return Puzzle(
      seed: json['seed'] as String,
      levelNumber: json['level_number'] as int?,
      levelType: levelType,
      isBoss: json['is_boss'] as bool? ?? false,
      wordSlots: wordSlots,
      intersections: intersections,
      letterPool: letterPool,
      constraintTiers: constraintTiers,
      metadata: json['metadata'] != null
          ? _toStringDynamicMap(json['metadata'])
          : {},
    );
  }

  /// Deserialize a [Puzzle] from a JSON string.
  Puzzle fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    return fromJson(decoded as Map<String, dynamic>);
  }

  /// Serialize a list of puzzles to a JSON string (for pre-generated levels file).
  String serializeLevelFile(List<Puzzle> puzzles) {
    final maps = puzzles.map(toJson).toList();
    return const JsonEncoder.withIndent('  ').convert({'levels': maps});
  }

  /// Deserialize a list of puzzles from the levels file JSON string.
  List<Puzzle> deserializeLevelFile(String jsonStr) {
    final decoded = _toStringDynamicMap(jsonDecode(jsonStr));
    final levels = decoded['levels'] as List<dynamic>;
    return levels.map((l) => fromJson(_toStringDynamicMap(l))).toList();
  }
}
