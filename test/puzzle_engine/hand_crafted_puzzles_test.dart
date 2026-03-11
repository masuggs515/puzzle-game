// test/puzzle_engine/hand_crafted_puzzles_test.dart
//
// Validates all 50 hand-crafted puzzles:
//   - Deserializes correctly from JSON
//   - All assigned words pass PuzzleValidator
//   - Grid coordinates are geometrically consistent (intersections map to
//     the same (row, col) cell for both intersecting slots)
//   - No accidental cell overlaps between non-intersecting slots

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/serialization/puzzle_serializer.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

// ---------------------------------------------------------------------------
// Geometry helpers (mirrors CrosswordGridWidget._computeGrid logic)
// ---------------------------------------------------------------------------

(int, int) _cell(WordSlot slot, int pos) {
  return slot.isHorizontal
      ? (slot.gridRow, slot.gridCol + pos)
      : (slot.gridRow + pos, slot.gridCol);
}

List<String> _geometryErrors(Puzzle puzzle) {
  final errors = <String>[];
  final slots = {for (final s in puzzle.wordSlots) s.id: s};

  // Check every declared intersection maps to the same grid cell.
  for (final ix in puzzle.intersections) {
    final slotA = slots[ix.slotAId]!;
    final slotB = slots[ix.slotBId]!;
    final cellA = _cell(slotA, ix.positionInA);
    final cellB = _cell(slotB, ix.positionInB);
    if (cellA != cellB) {
      errors.add(
        'Intersection slot${ix.slotAId}[${ix.positionInA}] @ $cellA '
        '!= slot${ix.slotBId}[${ix.positionInB}] @ $cellB',
      );
    }
  }

  // Check no undeclared cell overlaps.
  final declaredPairs = <(int, int)>{};
  for (final ix in puzzle.intersections) {
    declaredPairs.add((ix.slotAId, ix.slotBId));
    declaredPairs.add((ix.slotBId, ix.slotAId));
  }

  final cellToSlots = <(int, int), List<int>>{};
  for (final slot in puzzle.wordSlots) {
    final len = slot.requiredLength ?? 0;
    for (int pos = 0; pos < len; pos++) {
      final c = _cell(slot, pos);
      cellToSlots.putIfAbsent(c, () => []).add(slot.id);
    }
  }

  for (final entry in cellToSlots.entries) {
    final occupants = entry.value;
    if (occupants.length <= 1) continue;
    for (int i = 0; i < occupants.length; i++) {
      for (int j = i + 1; j < occupants.length; j++) {
        final si = occupants[i];
        final sj = occupants[j];
        if (!declaredPairs.contains((si, sj))) {
          errors.add(
            'Undeclared overlap at ${entry.key}: slot$si and slot$sj',
          );
        }
      }
    }
  }

  return errors;
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  late PuzzleValidator validator;
  late PuzzleSerializer serializer;
  late List<Map<String, dynamic>> rawPuzzles;

  setUpAll(() {
    // Load word lists using dart:io (test environment, not Flutter assets).
    final loader = WordListLoader.fromFiles();
    final answerSet = loader.answerWords.toSet();
    final allWords = loader.allValidWords;

    validator = PuzzleValidator(answerWordSet: answerSet, allValidWords: allWords);

    final library = ConstraintLibrary.build(validWords: allWords);
    serializer = PuzzleSerializer(library: library);

    final jsonStr = File('assets/puzzles/hand_crafted_001_050.json').readAsStringSync();
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    rawPuzzles = (decoded['puzzles'] as List).cast<Map<String, dynamic>>();
  });

  group('Hand-crafted puzzles — all 50', () {
    test('file contains exactly 50 puzzles', () {
      expect(rawPuzzles.length, equals(50));
    });

    for (int idx = 0; idx < 50; idx++) {
      // Use a closure to capture the index correctly.
      final capturedIdx = idx;

      test('puzzle ${capturedIdx + 1} deserializes, validates, and has consistent geometry', () {
        final raw = rawPuzzles[capturedIdx];
        final levelNumber = raw['level_number'] as int;

        // Deserialize.
        final puzzle = serializer.fromJson(raw);
        expect(puzzle.wordSlots.isNotEmpty, isTrue,
            reason: 'Level $levelNumber has no word slots');

        // Every slot must have an assigned word.
        for (final slot in puzzle.wordSlots) {
          expect(slot.assignedWord, isNotNull,
              reason: 'Level $levelNumber slot ${slot.id} missing assigned_word');
          expect(slot.assignedWord, isNotEmpty,
              reason: 'Level $levelNumber slot ${slot.id} has empty assigned_word');
        }

        // PuzzleValidator checks: word list, constraints, intersection letters,
        // duplicate words, letter pool coverage.
        final result = validator.validate(puzzle);
        expect(result.isValid, isTrue,
            reason: 'Level $levelNumber failed validation: ${result.issues.join('; ')}');

        // Geometry: intersections must map to the same grid cell; no accidental overlaps.
        final geoErrors = _geometryErrors(puzzle);
        expect(geoErrors, isEmpty,
            reason: 'Level $levelNumber geometry errors: ${geoErrors.join('; ')}');
      });
    }
  });
}
