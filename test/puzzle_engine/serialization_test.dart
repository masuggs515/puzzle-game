import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/serialization/puzzle_serializer.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

class _AcceptAllConstraint extends Constraint {
  const _AcceptAllConstraint()
      : super(id: 'accept_all', tier: 1, displayText: 'Any word');

  @override
  bool validate(String word) => true;
}

void main() {
  setUp(() {
    CategoryListLoader.clearCache();
    // Preload minimal categories needed for constraint library build
    CategoryListLoader.preload('animals', {'cat', 'dog'});
    CategoryListLoader.preload('colors', {'red', 'blue'});
    CategoryListLoader.preload('foods', {'bread', 'cake'});
    CategoryListLoader.preload('countries', {'france', 'spain'});
    CategoryListLoader.preload('vegetables', {'carrot', 'onion'});
    CategoryListLoader.preload('sports', {'golf', 'tennis'});
    CategoryListLoader.preload('body_parts', {'arm', 'leg'});
    CategoryListLoader.preload('weather', {'rain', 'snow'});
    CategoryListLoader.preload('vehicles', {'car', 'bus'});
    CategoryListLoader.preload('clothing', {'hat', 'coat'});
    CategoryListLoader.preload('fruits', {'apple', 'mango'});
    CategoryListLoader.preload('water_bodies', {'lake', 'river'});
    CategoryListLoader.preload('kitchen_items', {'pan', 'bowl'});
  });

  late ConstraintLibrary library;
  late PuzzleSerializer serializer;

  setUp(() {
    library = ConstraintLibrary.build(validWords: {'cat', 'dog', 'hat'});
    serializer = PuzzleSerializer(library: library);
  });

  Puzzle buildTestPuzzle() {
    final constraint = ConstraintAssignment(
      tier: 1,
      constraintId: 'accept_all',
      displayText: 'Any word',
      validator: const _AcceptAllConstraint(),
    );

    return Puzzle(
      seed: 'test-seed-42',
      levelNumber: 7,
      levelType: LevelType.puzzle,
      isBoss: false,
      wordSlots: [
        WordSlot(
          id: 0,
          constraint: constraint,
          requiredLength: 3,
          assignedWord: 'cat',
        ),
        WordSlot(
          id: 1,
          constraint: constraint,
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
      letterPool: ['a', 'c', 'h', 't'],
      constraintTiers: [1],
      metadata: {'test_key': 'test_value'},
    );
  }

  group('PuzzleSerializer', () {
    test('toJson produces expected structure', () {
      final puzzle = buildTestPuzzle();
      final json = serializer.toJson(puzzle);

      expect(json['seed'], equals('test-seed-42'));
      expect(json['level_number'], equals(7));
      expect(json['level_type'], equals('puzzle'));
      expect(json['is_boss'], isFalse);
      expect(json['word_slots'], isA<List>());
      expect((json['word_slots'] as List).length, equals(2));
      expect(json['intersections'], isA<List>());
      expect((json['intersections'] as List).length, equals(1));
      expect(json['letter_pool'], equals(['a', 'c', 'h', 't']));
      expect(json['constraint_tiers'], equals([1]));
      expect(json['metadata'], containsPair('test_key', 'test_value'));
    });

    test('toJson word slot structure is correct', () {
      final puzzle = buildTestPuzzle();
      final json = serializer.toJson(puzzle);
      final slot0 = (json['word_slots'] as List)[0] as Map<String, dynamic>;

      expect(slot0['id'], equals(0));
      expect(slot0['constraint_id'], equals('accept_all'));
      expect(slot0['constraint_tier'], equals(1));
      expect(slot0['assigned_word'], equals('cat'));
      expect(slot0['required_length'], equals(3));
    });

    test('toJson intersection structure is correct', () {
      final puzzle = buildTestPuzzle();
      final json = serializer.toJson(puzzle);
      final intersection =
          (json['intersections'] as List)[0] as Map<String, dynamic>;

      expect(intersection['slot_a'], equals(0));
      expect(intersection['slot_b'], equals(1));
      expect(intersection['position_in_a'], equals(2));
      expect(intersection['position_in_b'], equals(2));
    });

    test('toJsonString produces valid JSON', () {
      final puzzle = buildTestPuzzle();
      final jsonStr = serializer.toJsonString(puzzle);

      // Should not throw
      expect(() => jsonDecode(jsonStr), returnsNormally);
    });

    test('fromJson round-trips correctly', () {
      final original = buildTestPuzzle();
      final json = serializer.toJson(original);
      final restored = serializer.fromJson(json);

      expect(restored.seed, equals(original.seed));
      expect(restored.levelNumber, equals(original.levelNumber));
      expect(restored.levelType, equals(original.levelType));
      expect(restored.isBoss, equals(original.isBoss));
      expect(restored.wordSlots.length, equals(original.wordSlots.length));
      expect(restored.intersections.length, equals(original.intersections.length));
      expect(restored.letterPool, equals(original.letterPool));
      expect(restored.constraintTiers, equals(original.constraintTiers));
    });

    test('fromJson restores word slot assignments', () {
      final original = buildTestPuzzle();
      final json = serializer.toJson(original);
      final restored = serializer.fromJson(json);

      expect(restored.wordSlots[0].assignedWord, equals('cat'));
      expect(restored.wordSlots[1].assignedWord, equals('hat'));
    });

    test('fromJson restores intersections', () {
      final original = buildTestPuzzle();
      final json = serializer.toJson(original);
      final restored = serializer.fromJson(json);

      final intersection = restored.intersections[0];
      expect(intersection.slotAId, equals(0));
      expect(intersection.slotBId, equals(1));
      expect(intersection.positionInA, equals(2));
      expect(intersection.positionInB, equals(2));
    });

    test('fromJsonString round-trips correctly', () {
      final original = buildTestPuzzle();
      final jsonStr = serializer.toJsonString(original);
      final restored = serializer.fromJsonString(jsonStr);

      expect(restored.seed, equals(original.seed));
      expect(restored.wordSlots.length, equals(original.wordSlots.length));
    });

    test('serializeLevelFile and deserializeLevelFile round-trip', () {
      final puzzles = [buildTestPuzzle(), buildTestPuzzle()];
      final jsonStr = serializer.serializeLevelFile(puzzles);
      final restored = serializer.deserializeLevelFile(jsonStr);

      expect(restored.length, equals(2));
      expect(restored[0].seed, equals(puzzles[0].seed));
    });

    test('handles unknown constraint id gracefully', () {
      final json = {
        'seed': 'test',
        'level_number': 1,
        'level_type': 'puzzle',
        'is_boss': false,
        'word_slots': [
          {
            'id': 0,
            'constraint_id': 'unknown_future_constraint',
            'constraint_tier': 9,
            'display_text': 'Some future constraint',
            'required_length': null,
            'assigned_word': 'cat',
          },
        ],
        'intersections': [],
        'letter_pool': ['a', 'c', 't'],
        'constraint_tiers': [9],
        'metadata': {},
      };

      // Should not throw
      expect(() => serializer.fromJson(json), returnsNormally);
      final puzzle = serializer.fromJson(json);
      expect(puzzle.wordSlots[0].assignedWord, equals('cat'));
    });
  });
}
