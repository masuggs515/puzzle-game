// test/game/game_state_test.dart
// Phase 4 — Core Game
// Pure Dart unit tests for GameState, FeedbackMessage, GamePhase,
// and LevelCompleteArgs. No Flutter widgets, no Flame.

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/models/level_complete_args.dart';
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
        (i) => WordSlot(id: i, constraint: _mockAssignment()),
      ),
      intersections: const [],
      letterPool: const ['a', 'b', 'c', 'd'],
      constraintTiers: const [1],
      metadata: const {},
    );

GameState _baseState({int wordCount = 2, int hintsUsed = 0}) => GameState(
      phase: GamePhase.idle,
      puzzle: _minimalPuzzle(wordCount: wordCount),
      solvedWords: const {},
      currentPath: const [],
      currentWord: '',
      hintsUsedThisLevel: hintsUsed,
      attemptsThisLevel: 0,
      activeHintSlotId: null,
      hintedTileIndices: const {},
      feedbackMessage: null,
      levelStartTime: DateTime(2026, 1, 1),
      coinBalance: 100,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GamePhase enum', () {
    test('contains all required values', () {
      const values = GamePhase.values;
      expect(values, contains(GamePhase.loading));
      expect(values, contains(GamePhase.idle));
      expect(values, contains(GamePhase.dragging));
      expect(values, contains(GamePhase.submitted));
      expect(values, contains(GamePhase.feedbackCorrect));
      expect(values, contains(GamePhase.feedbackWrongWord));
      expect(values, contains(GamePhase.feedbackWrongConstraint));
      expect(values, contains(GamePhase.hintActive));
      expect(values, contains(GamePhase.levelComplete));
      expect(values, contains(GamePhase.paused));
    });

    test('has exactly 10 values', () {
      expect(GamePhase.values.length, 10);
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
      expect(msg.message, 'Valid word, wrong constraint');
      expect(msg.constraintText, 'Must start with a vowel');
    });

    test('feedbackCorrect type can be constructed', () {
      const msg = FeedbackMessage(
        type: FeedbackType.correct,
        message: 'Great!',
      );

      expect(msg.type, FeedbackType.correct);
      expect(msg.message, 'Great!');
      expect(msg.constraintText, isNull);
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
      final puzzle = _minimalPuzzle(wordCount: 3);
      final state = GameState(
        phase: GamePhase.idle,
        puzzle: puzzle,
        solvedWords: const {0: 'cat'},
        currentPath: const [],
        currentWord: '',
        hintsUsedThisLevel: 0,
        attemptsThisLevel: 0,
        activeHintSlotId: null,
        hintedTileIndices: const {},
        feedbackMessage: null,
        levelStartTime: DateTime(2026, 1, 1),
        coinBalance: 100,
      );
      expect(state.isComplete, isFalse);
    });

    test('true when all words solved (2 slots, 2 solved)', () {
      final puzzle = _minimalPuzzle(wordCount: 2);
      final state = GameState(
        phase: GamePhase.idle,
        puzzle: puzzle,
        solvedWords: const {0: 'cat', 1: 'dog'},
        currentPath: const [],
        currentWord: '',
        hintsUsedThisLevel: 0,
        attemptsThisLevel: 0,
        activeHintSlotId: null,
        hintedTileIndices: const {},
        feedbackMessage: null,
        levelStartTime: DateTime(2026, 1, 1),
        coinBalance: 100,
      );
      expect(state.isComplete, isTrue);
    });

    test('true when all words solved (4 slots, 4 solved)', () {
      final puzzle = _minimalPuzzle(wordCount: 4);
      final state = GameState(
        phase: GamePhase.idle,
        puzzle: puzzle,
        solvedWords: const {0: 'cat', 1: 'dog', 2: 'rat', 3: 'bat'},
        currentPath: const [],
        currentWord: '',
        hintsUsedThisLevel: 0,
        attemptsThisLevel: 0,
        activeHintSlotId: null,
        hintedTileIndices: const {},
        feedbackMessage: null,
        levelStartTime: DateTime(2026, 1, 1),
        coinBalance: 100,
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
      expect(copy.currentPath, original.currentPath);
      expect(copy.currentWord, original.currentWord);
      expect(copy.hintsUsedThisLevel, original.hintsUsedThisLevel);
      expect(copy.attemptsThisLevel, original.attemptsThisLevel);
      expect(copy.activeHintSlotId, original.activeHintSlotId);
      expect(copy.hintedTileIndices, original.hintedTileIndices);
      expect(copy.feedbackMessage, original.feedbackMessage);
      expect(copy.levelStartTime, original.levelStartTime);
      expect(copy.coinBalance, original.coinBalance);
    });

    test('updates phase without touching other fields', () {
      final original = _baseState();
      final copy = original.copyWith(phase: GamePhase.dragging);

      expect(copy.phase, GamePhase.dragging);
      expect(copy.currentWord, original.currentWord);
      expect(copy.hintsUsedThisLevel, original.hintsUsedThisLevel);
      expect(copy.coinBalance, original.coinBalance);
    });

    test('updates solvedWords', () {
      final original = _baseState(wordCount: 2);
      final copy = original.copyWith(solvedWords: {0: 'apple'});

      expect(copy.solvedWords, {0: 'apple'});
      expect(copy.phase, original.phase);
    });

    test('updates hintsUsedThisLevel', () {
      final original = _baseState(hintsUsed: 0);
      final copy = original.copyWith(hintsUsedThisLevel: 2);

      expect(copy.hintsUsedThisLevel, 2);
      expect(copy.stars, 2);
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

    test('clears activeHintSlotId when clearActiveHintSlotId is true', () {
      final original = _baseState().copyWith(activeHintSlotId: 3);

      expect(original.activeHintSlotId, 3);

      final cleared = original.copyWith(clearActiveHintSlotId: true);
      expect(cleared.activeHintSlotId, isNull);
    });

    test('updates currentWord and currentPath together', () {
      final original = _baseState();
      final copy = original.copyWith(
        currentWord: 'cat',
        currentPath: [0, 1, 2],
      );

      expect(copy.currentWord, 'cat');
      expect(copy.currentPath, [0, 1, 2]);
    });

    test('updates coinBalance', () {
      final original = _baseState();
      final copy = original.copyWith(coinBalance: 250);

      expect(copy.coinBalance, 250);
      expect(copy.phase, original.phase);
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

    test('explicit non-default values are stored correctly', () {
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
}
