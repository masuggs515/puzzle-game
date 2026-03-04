// lib/features/game/providers/game_provider.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Game State Machine
//
// Async puzzle loader + synchronous game state notifier.
// No code generation — plain StateNotifier / FutureProvider.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_game/core/constants/game_constants.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/providers/puzzle_repository_provider.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

// ---------------------------------------------------------------------------
// Async puzzle loader — triggers on every level number change.
// ---------------------------------------------------------------------------

final gamePuzzleProvider = FutureProvider.family<Puzzle, int>(
  (ref, levelNumber) async {
    final repo = ref.read(puzzleRepositoryProvider);
    return repo.getPuzzleByLevel(levelNumber);
  },
);

// ---------------------------------------------------------------------------
// GameNotifier — owns all mutable game state for one play-through.
// Created as local state in GameScreen.
//
// Word validation is injected as a callback so the notifier has no
// dependency on WidgetRef (which cannot be stored in a StateNotifier).
// ---------------------------------------------------------------------------

typedef WordValidator = Future<bool> Function(String word);

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier({
    required Puzzle puzzle,
    required WordValidator wordValidator,
  })  : _wordValidator = wordValidator,
        super(GameState(
          phase: GamePhase.idle,
          puzzle: puzzle,
          solvedWords: const {},
          currentPath: const [],
          currentWord: '',
          hintsUsedThisLevel: 0,
          attemptsThisLevel: 0,
          activeHintSlotId: null,
          hintedTileIndices: const {},
          feedbackMessage: null,
          levelStartTime: DateTime.now(),
          coinBalance: 0,
        ));

  final WordValidator _wordValidator;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  // Public read accessor so GameScreen can get current state without
  // going through the protected StateNotifier.state field.
  GameState get currentState => state;

  // -------------------------------------------------------------------------
  // Drag mechanic
  // -------------------------------------------------------------------------

  void onTileDragStart(int tileIndex) {
    final letters = state.puzzle.letterPool;
    final letter = tileIndex < letters.length ? letters[tileIndex] : '';
    state = state.copyWith(
      phase: GamePhase.dragging,
      currentPath: [tileIndex],
      currentWord: letter,
    );
  }

  void onTileDragEnter(int tileIndex) {
    if (state.phase != GamePhase.dragging) return;
    // No revisiting tiles already in the path
    if (state.currentPath.contains(tileIndex)) return;

    final newPath = List<int>.from(state.currentPath)..add(tileIndex);
    final letters = state.puzzle.letterPool;
    final newWord = newPath
        .map((i) => i < letters.length ? letters[i] : '')
        .join();
    state = state.copyWith(
      currentPath: newPath,
      currentWord: newWord,
    );
  }

  void onTileDragEnd() {
    // Path stays visible — player submits or clears manually
    if (state.phase == GamePhase.dragging) {
      state = state.copyWith(phase: GamePhase.idle);
    }
  }

  void onPathCleared() {
    state = state.copyWith(
      phase: GamePhase.idle,
      currentPath: const [],
      currentWord: '',
    );
  }

  // -------------------------------------------------------------------------
  // Submission
  // -------------------------------------------------------------------------

  Future<void> onSubmit(int targetSlotId) async {
    final word = state.currentWord;
    if (word.length < GameConstants.minWordLength) return;

    // Don't submit during active feedback phases
    if (state.phase == GamePhase.feedbackWrongWord ||
        state.phase == GamePhase.feedbackWrongConstraint ||
        state.phase == GamePhase.feedbackCorrect) {
      return;
    }

    state = state.copyWith(
      phase: GamePhase.submitted,
      attemptsThisLevel: state.attemptsThisLevel + 1,
    );

    // Step 1: Dictionary check
    final isValidWord = await _wordValidator(word);
    if (!mounted) return;
    if (!isValidWord) {
      _showFeedback(FeedbackType.wrongWord, 'Not a valid word');
      return;
    }

    // Step 2: Find the target slot
    final matchingSlots = state.puzzle.wordSlots
        .where((s) => s.id == targetSlotId)
        .toList();
    if (matchingSlots.isEmpty) {
      _showFeedback(FeedbackType.wrongWord, 'Invalid slot');
      return;
    }
    final slot = matchingSlots.first;

    // Step 3: Constraint check (real word that fails the slot's constraint)
    final passesConstraint = slot.constraint.validator.validate(word);
    if (!passesConstraint) {
      _showFeedback(
        FeedbackType.wrongConstraint,
        'Wrong — ${slot.constraint.displayText}',
        constraintText: slot.constraint.displayText,
      );
      return;
    }

    // Step 4: Required-length check (constraint-class violation)
    final requiredLength = slot.requiredLength;
    if (requiredLength != null && word.length != requiredLength) {
      _showFeedback(
        FeedbackType.wrongConstraint,
        'Word must be $requiredLength letters',
      );
      return;
    }

    // Step 5: Intersection consistency (valid word, wrong crossing letter)
    if (!_validateIntersections(word, targetSlotId)) {
      _showFeedback(
        FeedbackType.wrongConstraint,
        "Letters don't match the crossing word",
      );
      return;
    }

    // Correct!
    final newSolved = Map<int, String>.from(state.solvedWords)
      ..[targetSlotId] = word;
    state = state.copyWith(
      phase: GamePhase.feedbackCorrect,
      solvedWords: newSolved,
      currentPath: const [],
      currentWord: '',
      feedbackMessage: const FeedbackMessage(
        type: FeedbackType.correct,
        message: 'Correct!',
      ),
    );

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: GameConstants.feedbackDurationMs),
      () {
        if (!mounted) return;
        if (state.isComplete) {
          state = state.copyWith(
            phase: GamePhase.levelComplete,
            clearFeedbackMessage: true,
          );
        } else {
          state = state.copyWith(
            phase: GamePhase.idle,
            clearFeedbackMessage: true,
          );
        }
      },
    );
  }

  // -------------------------------------------------------------------------
  // Feedback helpers
  // -------------------------------------------------------------------------

  void _showFeedback(
    FeedbackType type,
    String message, {
    String? constraintText,
  }) {
    _feedbackTimer?.cancel();

    final phase = type == FeedbackType.wrongWord
        ? GamePhase.feedbackWrongWord
        : GamePhase.feedbackWrongConstraint;

    state = state.copyWith(
      phase: phase,
      currentPath: const [],
      currentWord: '',
      feedbackMessage: FeedbackMessage(
        type: type,
        message: message,
        constraintText: constraintText,
      ),
    );

    _feedbackTimer = Timer(
      const Duration(milliseconds: GameConstants.feedbackDurationMs),
      () {
        if (!mounted) return;
        state = state.copyWith(
          phase: GamePhase.idle,
          clearFeedbackMessage: true,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Intersection validation
  // -------------------------------------------------------------------------

  /// Validates that [word] placed in [slotId] is consistent with all
  /// already-solved words at their shared intersection positions.
  bool _validateIntersections(String word, int slotId) {
    for (final intersection in state.puzzle.intersections) {
      final int myPos;
      final int otherSlotId;
      final int otherPos;

      if (intersection.slotAId == slotId) {
        myPos = intersection.positionInA;
        otherSlotId = intersection.slotBId;
        otherPos = intersection.positionInB;
      } else if (intersection.slotBId == slotId) {
        myPos = intersection.positionInB;
        otherSlotId = intersection.slotAId;
        otherPos = intersection.positionInA;
      } else {
        continue;
      }

      final otherWord = state.solvedWords[otherSlotId];
      if (otherWord == null) continue; // other slot not yet solved

      if (myPos >= word.length || otherPos >= otherWord.length) return false;

      if (word[myPos].toLowerCase() != otherWord[otherPos].toLowerCase()) {
        return false;
      }
    }
    return true;
  }
}
