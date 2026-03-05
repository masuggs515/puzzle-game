// test/game/game_state_test.dart
// Phase 4 — Core Game (tile-placement redesign)
// Pure Dart unit tests for GameState, CellKey, PoolTile, FeedbackMessage,
// SlotResult, GamePhase, and LevelCompleteArgs. No Flutter widgets, no Flame.

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
import 'package:puzzle_game/features/game/providers/game_provider.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/models/constraint_assignment.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

// ---------------------------------------------------------------------------
// Minimal constraint used only in tests — always returns true.
// ---------------------------------------------------------------------------

class _MockConstraint extends Constraint {
  const _MockConstraint()
      : super(id: 'mock', tier: 1, displayText: 'A mock constraint');

  @override
  bool validate(String word) => true;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ConstraintAssignment _mockAssignment() => ConstraintAssignment(
      tier: 1,
      constraintId: 'mock',
      displayText: 'A mock constraint',
      validator: const _MockConstraint(),
    );

Puzzle _minimalPuzzle({int wordCount = 2}) => Puzzle(
      seed: 'test-seed',
      levelNumber: 1,
      levelType: LevelType.sprint,
      isBoss: false,
      wordSlots: List.generate(
        wordCount,
        (i) => WordSlot(
          id: i,
          constraint: _mockAssignment(),
          requiredLength: 3,
          gridRow: i,
          gridCol: 0,
          isHorizontal: true,
        ),
      ),
      intersections: const [],
      letterPool: const ['a', 'b', 'c', 'd', 'e', 'f'],
      constraintTiers: const [1],
      metadata: const {},
    );

/// Build a base state with an empty tile list (sufficient for most model tests).
GameState _baseState({int wordCount = 2, int hintsUsed = 0}) => GameState(
      phase: GamePhase.idle,
      puzzle: _minimalPuzzle(wordCount: wordCount),
      solvedWords: const {},
      tiles: const [],
      slotResults: const {},
      hintsUsedThisLevel: hintsUsed,
      attemptsThisLevel: 0,
      feedbackMessage: null,
      levelStartTime: DateTime(2026, 1, 1),
      coinBalance: 100,
    );

/// Build a state with a real tile list for tile-placement tests.
GameState _stateWithTiles({int wordCount = 1}) {
  final puzzle = _minimalPuzzle(wordCount: wordCount);
  final tiles = List.generate(
    puzzle.letterPool.length,
    (i) => PoolTile(id: i, letter: puzzle.letterPool[i]),
  );
  return GameState(
    phase: GamePhase.idle,
    puzzle: puzzle,
    solvedWords: const {},
    tiles: tiles,
    slotResults: const {},
    hintsUsedThisLevel: 0,
    attemptsThisLevel: 0,
    feedbackMessage: null,
    levelStartTime: DateTime(2026, 1, 1),
    coinBalance: 0,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('GamePhase enum', () {
    test('contains all required values', () {
      const values = GamePhase.values;
      expect(values, contains(GamePhase.loading));
      expect(values, contains(GamePhase.idle));
      expect(values, contains(GamePhase.submitted));
      expect(values, contains(GamePhase.feedbackCorrect));
      expect(values, contains(GamePhase.feedbackWrongWord));
      expect(values, contains(GamePhase.feedbackWrongConstraint));
      expect(values, contains(GamePhase.hintActive));
      expect(values, contains(GamePhase.levelComplete));
      expect(values, contains(GamePhase.paused));
    });

    test('does not contain dragging (removed in redesign)', () {
      expect(GamePhase.values.map((v) => v.name), isNot(contains('dragging')));
    });

    test('has exactly 9 values', () {
      expect(GamePhase.values.length, 9);
    });
  });

  // -------------------------------------------------------------------------
  group('SlotResult enum', () {
    test('contains all required values', () {
      expect(SlotResult.values, contains(SlotResult.unvalidated));
      expect(SlotResult.values, contains(SlotResult.correct));
      expect(SlotResult.values, contains(SlotResult.wrongWord));
      expect(SlotResult.values, contains(SlotResult.wrongConstraint));
    });
  });

  // -------------------------------------------------------------------------
  group('CellKey', () {
    test('equality — same slotId and positionInSlot are equal', () {
      const a = CellKey(slotId: 0, positionInSlot: 2);
      const b = CellKey(slotId: 0, positionInSlot: 2);
      expect(a, equals(b));
    });

    test('equality — different slotId are not equal', () {
      const a = CellKey(slotId: 0, positionInSlot: 2);
      const b = CellKey(slotId: 1, positionInSlot: 2);
      expect(a, isNot(equals(b)));
    });

    test('equality — different positionInSlot are not equal', () {
      const a = CellKey(slotId: 0, positionInSlot: 0);
      const b = CellKey(slotId: 0, positionInSlot: 1);
      expect(a, isNot(equals(b)));
    });

    test('hashCode — equal keys have same hashCode', () {
      const a = CellKey(slotId: 3, positionInSlot: 1);
      const b = CellKey(slotId: 3, positionInSlot: 1);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode — different keys typically have different hashCode', () {
      const a = CellKey(slotId: 0, positionInSlot: 0);
      const b = CellKey(slotId: 1, positionInSlot: 0);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('toString returns human-readable string', () {
      const k = CellKey(slotId: 2, positionInSlot: 3);
      expect(k.toString(), contains('2'));
      expect(k.toString(), contains('3'));
    });

    test('can be used as a Map key', () {
      final map = <CellKey, String>{};
      const k = CellKey(slotId: 0, positionInSlot: 0);
      map[k] = 'hello';
      expect(map[const CellKey(slotId: 0, positionInSlot: 0)], 'hello');
    });
  });

  // -------------------------------------------------------------------------
  group('PoolTile', () {
    test('isInPool is true when placedAt is null', () {
      const tile = PoolTile(id: 0, letter: 'A');
      expect(tile.isInPool, isTrue);
    });

    test('isInPool is false when placedAt is set', () {
      const tile = PoolTile(
        id: 0,
        letter: 'A',
        placedAt: CellKey(slotId: 0, positionInSlot: 0),
      );
      expect(tile.isInPool, isFalse);
    });

    test('withPlacement returns new tile placed at cell', () {
      const tile = PoolTile(id: 1, letter: 'B');
      const cell = CellKey(slotId: 0, positionInSlot: 1);
      final placed = tile.withPlacement(cell);

      expect(placed.id, 1);
      expect(placed.letter, 'B');
      expect(placed.placedAt, equals(cell));
      expect(placed.isInPool, isFalse);
    });

    test('returnToPool clears placement', () {
      const cell = CellKey(slotId: 0, positionInSlot: 0);
      const tile = PoolTile(id: 2, letter: 'C', placedAt: cell);
      final returned = tile.returnToPool();

      expect(returned.id, 2);
      expect(returned.letter, 'C');
      expect(returned.isInPool, isTrue);
      expect(returned.placedAt, isNull);
    });

    test('withPlacement does not mutate original', () {
      const tile = PoolTile(id: 0, letter: 'A');
      const cell = CellKey(slotId: 0, positionInSlot: 0);
      tile.withPlacement(cell);
      expect(tile.isInPool, isTrue); // original unchanged
    });
  });

  // -------------------------------------------------------------------------
  group('GameState.tileAt', () {
    test('returns tile placed at matching CellKey', () {
      const cell = CellKey(slotId: 0, positionInSlot: 0);
      const tile = PoolTile(id: 0, letter: 'A', placedAt: cell);
      final state = _baseState().copyWith(tiles: [tile]);

      expect(state.tileAt(cell), equals(tile));
    });

    test('returns null when no tile at that cell', () {
      const cell = CellKey(slotId: 0, positionInSlot: 0);
      const otherCell = CellKey(slotId: 0, positionInSlot: 1);
      const tile = PoolTile(id: 0, letter: 'A', placedAt: cell);
      final state = _baseState().copyWith(tiles: [tile]);

      expect(state.tileAt(otherCell), isNull);
    });

    test('returns null for pool tiles', () {
      const tile = PoolTile(id: 0, letter: 'A'); // placedAt == null
      final state = _baseState().copyWith(tiles: [tile]);
      expect(
        state.tileAt(const CellKey(slotId: 0, positionInSlot: 0)),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('GameState.wordForSlot', () {
    test('returns null when slot has no requiredLength', () {
      final puzzle = Puzzle(
        seed: 'test',
        levelNumber: 1,
        levelType: LevelType.sprint,
        isBoss: false,
        wordSlots: [
          WordSlot(
            id: 0,
            constraint: _mockAssignment(),
            // requiredLength intentionally omitted → null
          ),
        ],
        intersections: const [],
        letterPool: const ['a', 'b', 'c'],
        constraintTiers: const [1],
        metadata: const {},
      );
      final state = GameState(
        phase: GamePhase.idle,
        puzzle: puzzle,
        solvedWords: const {},
        tiles: const [],
        slotResults: const {},
        hintsUsedThisLevel: 0,
        attemptsThisLevel: 0,
        feedbackMessage: null,
        levelStartTime: DateTime(2026, 1, 1),
        coinBalance: 0,
      );

      expect(state.wordForSlot(puzzle.wordSlots[0]), isNull);
    });

    test('returns null when not all cells are filled', () {
      final state = _stateWithTiles();
      final slot = state.puzzle.wordSlots[0]; // requiredLength = 3

      // Only place tile in position 0
      final tiles = List<PoolTile>.from(state.tiles);
      tiles[0] = tiles[0].withPlacement(CellKey(slotId: slot.id, positionInSlot: 0));
      final s = state.copyWith(tiles: tiles);

      expect(s.wordForSlot(slot), isNull);
    });

    test('returns assembled word when all cells are filled', () {
      final state = _stateWithTiles();
      final slot = state.puzzle.wordSlots[0]; // requiredLength = 3, letters a,b,c,d,e,f

      final tiles = List<PoolTile>.from(state.tiles);
      // Place tiles 0,1,2 at positions 0,1,2 of slot 0
      for (int i = 0; i < 3; i++) {
        tiles[i] = tiles[i].withPlacement(CellKey(slotId: slot.id, positionInSlot: i));
      }
      final s = state.copyWith(tiles: tiles);

      // letterPool is ['a','b','c','d','e','f'], tiles 0,1,2 are a,b,c
      expect(s.wordForSlot(slot), 'abc');
    });
  });

  // -------------------------------------------------------------------------
  group('GameState.stars', () {
    test('returns 3 stars when 0 hints used (threeStarMaxHints = 0)', () {
      final state = _baseState(hintsUsed: 0);
      expect(state.stars, 3);
    });

    test('returns 2 stars when 1 hint used', () {
      final state = _baseState(hintsUsed: 1);
      expect(state.stars, 2);
    });

    test('returns 2 stars when 2 hints used (twoStarMaxHints = 2)', () {
      final state = _baseState(hintsUsed: 2);
      expect(state.stars, 2);
    });

    test('returns 1 star when 3 hints used', () {
      final state = _baseState(hintsUsed: 3);
      expect(state.stars, 1);
    });

    test('returns 1 star when 5 hints used', () {
      final state = _baseState(hintsUsed: 5);
      expect(state.stars, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('GameState.isComplete', () {
    test('false when no words solved', () {
      final state = _baseState(wordCount: 2);
      expect(state.isComplete, isFalse);
    });

    test('false when only some words solved', () {
      final state = _baseState(wordCount: 3).copyWith(
        solvedWords: {0: 'cat'},
      );
      expect(state.isComplete, isFalse);
    });

    test('true when all words solved (2 slots)', () {
      final state = _baseState(wordCount: 2).copyWith(
        solvedWords: {0: 'cat', 1: 'dog'},
      );
      expect(state.isComplete, isTrue);
    });

    test('true when all words solved (4 slots)', () {
      final state = _baseState(wordCount: 4).copyWith(
        solvedWords: {0: 'cat', 1: 'dog', 2: 'rat', 3: 'bat'},
      );
      expect(state.isComplete, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('GameState.copyWith', () {
    test('preserves all fields when nothing is overridden', () {
      final original = _baseState(hintsUsed: 1);
      final copy = original.copyWith();

      expect(copy.phase, original.phase);
      expect(copy.puzzle, original.puzzle);
      expect(copy.solvedWords, original.solvedWords);
      expect(copy.tiles, original.tiles);
      expect(copy.slotResults, original.slotResults);
      expect(copy.hintsUsedThisLevel, original.hintsUsedThisLevel);
      expect(copy.attemptsThisLevel, original.attemptsThisLevel);
      expect(copy.feedbackMessage, original.feedbackMessage);
      expect(copy.levelStartTime, original.levelStartTime);
      expect(copy.coinBalance, original.coinBalance);
    });

    test('updates phase without touching other fields', () {
      final original = _baseState();
      final copy = original.copyWith(phase: GamePhase.submitted);

      expect(copy.phase, GamePhase.submitted);
      expect(copy.hintsUsedThisLevel, original.hintsUsedThisLevel);
      expect(copy.coinBalance, original.coinBalance);
    });

    test('updates solvedWords', () {
      final original = _baseState(wordCount: 2);
      final copy = original.copyWith(solvedWords: {0: 'apple'});

      expect(copy.solvedWords, {0: 'apple'});
      expect(copy.phase, original.phase);
    });

    test('updates hintsUsedThisLevel and stars reflect new value', () {
      final original = _baseState(hintsUsed: 0);
      final copy = original.copyWith(hintsUsedThisLevel: 2);

      expect(copy.hintsUsedThisLevel, 2);
      expect(copy.stars, 2);
    });

    test('updates slotResults', () {
      final original = _baseState();
      final copy = original.copyWith(
        slotResults: {0: SlotResult.correct, 1: SlotResult.wrongWord},
      );

      expect(copy.slotResults[0], SlotResult.correct);
      expect(copy.slotResults[1], SlotResult.wrongWord);
    });

    test('clears feedbackMessage when clearFeedbackMessage is true', () {
      const feedback = FeedbackMessage(
        type: FeedbackType.wrongWord,
        message: 'Not a word',
      );
      final original = _baseState().copyWith(feedbackMessage: feedback);
      expect(original.feedbackMessage, isNotNull);

      final cleared = original.copyWith(clearFeedbackMessage: true);
      expect(cleared.feedbackMessage, isNull);
    });

    test('clearFeedbackMessage=false keeps existing feedback', () {
      const feedback = FeedbackMessage(
        type: FeedbackType.wrongConstraint,
        message: 'Wrong logic',
        constraintText: 'Must be an animal',
      );
      final original = _baseState().copyWith(feedbackMessage: feedback);
      final copy = original.copyWith(clearFeedbackMessage: false);

      expect(copy.feedbackMessage, isNotNull);
      expect(copy.feedbackMessage!.message, 'Wrong logic');
    });

    test('updates coinBalance', () {
      final original = _baseState();
      final copy = original.copyWith(coinBalance: 250);

      expect(copy.coinBalance, 250);
      expect(copy.phase, original.phase);
    });

    test('updates tiles list', () {
      final original = _baseState();
      const newTile = PoolTile(id: 99, letter: 'Z');
      final copy = original.copyWith(tiles: [newTile]);

      expect(copy.tiles.length, 1);
      expect(copy.tiles.first.letter, 'Z');
    });
  });

  // -------------------------------------------------------------------------
  group('FeedbackMessage', () {
    test('stores type, message, and constraintText correctly', () {
      const msg = FeedbackMessage(
        type: FeedbackType.wrongWord,
        message: 'Not a real word',
        constraintText: null,
      );

      expect(msg.type, FeedbackType.wrongWord);
      expect(msg.message, 'Not a real word');
      expect(msg.constraintText, isNull);
    });

    test('stores constraintText when provided', () {
      const msg = FeedbackMessage(
        type: FeedbackType.wrongConstraint,
        message: 'Valid word, wrong constraint',
        constraintText: 'Must start with a vowel',
      );

      expect(msg.type, FeedbackType.wrongConstraint);
      expect(msg.constraintText, 'Must start with a vowel');
    });

    test('feedbackCorrect type can be constructed', () {
      const msg = FeedbackMessage(
        type: FeedbackType.correct,
        message: 'Great!',
      );

      expect(msg.type, FeedbackType.correct);
      expect(msg.constraintText, isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('LevelCompleteArgs', () {
    test('required fields are set correctly', () {
      const args = LevelCompleteArgs(levelNumber: 5, stars: 3);

      expect(args.levelNumber, 5);
      expect(args.stars, 3);
    });

    test('coinsEarned defaults to 0', () {
      const args = LevelCompleteArgs(levelNumber: 1, stars: 2);
      expect(args.coinsEarned, 0);
    });

    test('wasSkipped defaults to false', () {
      const args = LevelCompleteArgs(levelNumber: 1, stars: 2);
      expect(args.wasSkipped, isFalse);
    });

    test('achievementsUnlocked defaults to empty list', () {
      const args = LevelCompleteArgs(levelNumber: 1, stars: 2);
      expect(args.achievementsUnlocked, isEmpty);
    });

    test('explicit non-default values stored correctly', () {
      const args = LevelCompleteArgs(
        levelNumber: 10,
        stars: 1,
        coinsEarned: 20,
        wasSkipped: true,
        achievementsUnlocked: ['first_level', 'speed_run'],
      );

      expect(args.levelNumber, 10);
      expect(args.stars, 1);
      expect(args.coinsEarned, 20);
      expect(args.wasSkipped, isTrue);
      expect(args.achievementsUnlocked, ['first_level', 'speed_run']);
    });
  });

  // -------------------------------------------------------------------------
  // Regression test: tile pool must contain one tile per grid cell, not one
  // per unique letter. Level 1 (BEAR × BLUE, sharing B at pos 0) needs 7
  // tiles — not 6 — because E appears in both words at different positions.
  // -------------------------------------------------------------------------
  group('GameNotifier tile generation', () {
    Puzzle _level1Like() => Puzzle(
          seed: 'hc_001',
          levelNumber: 1,
          levelType: LevelType.sprint,
          isBoss: false,
          wordSlots: [
            WordSlot(
              id: 0,
              constraint: _mockAssignment(),
              requiredLength: 4,
              assignedWord: 'bear',
              gridRow: 0,
              gridCol: 0,
              isHorizontal: true,
            ),
            WordSlot(
              id: 1,
              constraint: _mockAssignment(),
              requiredLength: 4,
              assignedWord: 'blue',
              gridRow: 0,
              gridCol: 0,
              isHorizontal: false,
            ),
          ],
          intersections: const [
            Intersection(
              slotAId: 0,
              slotBId: 1,
              positionInA: 0,
              positionInB: 0,
            ),
          ],
          // letterPool kept for fallback; primary source is assignedWord
          letterPool: const ['b', 'e', 'a', 'r', 'l', 'u', 'e'],
          constraintTiers: const [1],
          metadata: const {},
        );

    GameNotifier _makeNotifier(Puzzle puzzle) => GameNotifier(
          puzzle: puzzle,
          wordValidator: (_) async => true,
        );

    test('Level 1 produces 7 tiles (4 + 4 words − 1 shared intersection)', () {
      final notifier = _makeNotifier(_level1Like());
      expect(notifier.currentState.tiles.length, 7);
      notifier.dispose();
    });

    test('tile letters match both words minus the shared intersection letter', () {
      final notifier = _makeNotifier(_level1Like());
      final letters = notifier.currentState.tiles.map((t) => t.letter).toList()
        ..sort();
      // BEAR(b,e,a,r) + BLUE(b,l,u,e) − shared B = a,b,e,e,l,r,u
      expect(letters, ['a', 'b', 'e', 'e', 'l', 'r', 'u']);
      notifier.dispose();
    });

    test('all tiles start in the pool (placedAt is null)', () {
      final notifier = _makeNotifier(_level1Like());
      expect(notifier.currentState.tiles.every((t) => t.isInPool), isTrue);
      notifier.dispose();
    });

    test('tile ids are unique', () {
      final notifier = _makeNotifier(_level1Like());
      final ids = notifier.currentState.tiles.map((t) => t.id).toSet();
      expect(ids.length, notifier.currentState.tiles.length);
      notifier.dispose();
    });

    test('falls back to letterPool when assignedWord is missing', () {
      // A puzzle with no assignedWord should fall back to letterPool (6 items).
      final puzzle = Puzzle(
        seed: 'fallback-seed',
        levelNumber: 99,
        levelType: LevelType.sprint,
        isBoss: false,
        wordSlots: [
          WordSlot(id: 0, constraint: _mockAssignment(), requiredLength: 3),
          WordSlot(id: 1, constraint: _mockAssignment(), requiredLength: 3),
        ],
        intersections: const [],
        letterPool: const ['x', 'y', 'z'],
        constraintTiers: const [1],
        metadata: const {},
      );
      final notifier = _makeNotifier(puzzle);
      expect(notifier.currentState.tiles.length, 3);
      notifier.dispose();
    });
  });
}
