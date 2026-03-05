// lib/features/game/providers/game_provider.dart
// Phase 4 — Core Game (tile-placement redesign)
// Spec: flutter-agent-spec.md § Game State Machine
//
// Async puzzle loader + synchronous game state notifier.
// No code generation — plain StateNotifier / FutureProvider.

import 'dart:async';
import 'dart:math';

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
          tiles: _buildTilesFromPuzzle(puzzle),
          slotResults: const {},
          hintsUsedThisLevel: 0,
          attemptsThisLevel: 0,
          feedbackMessage: null,
          levelStartTime: DateTime.now(),
          coinBalance: 0,
        ));

  final WordValidator _wordValidator;
  Timer? _feedbackTimer;

  /// Derives one tile per grid cell from the puzzle's word slots and
  /// intersections. Shared intersection cells contribute exactly one tile
  /// regardless of how many words pass through them.
  ///
  /// Requires [WordSlot.assignedWord] to be set on all slots. Falls back to
  /// [Puzzle.letterPool] (the pre-computed list) if any slot lacks a word —
  /// this handles puzzles that haven't had assigned_word set in the JSON yet.
  static List<PoolTile> _buildTilesFromPuzzle(Puzzle puzzle) {
    final hasAllWords = puzzle.wordSlots.every((s) => s.assignedWord != null);
    if (!hasAllWords) {
      // Fallback: build directly from the pre-computed letter pool.
      final letters = List<String>.from(puzzle.letterPool)
        ..shuffle(Random(puzzle.seed.hashCode));
      return List.generate(
        letters.length,
        (i) => PoolTile(id: i, letter: letters[i]),
      );
    }

    int tileId = 0;
    final tiles = <PoolTile>[];
    // Track processed intersection cells by their canonical key (slotA:posA).
    final intersectionsDone = <String>{};

    for (final slot in puzzle.wordSlots) {
      final word = slot.assignedWord!;
      final length = slot.requiredLength ?? word.length;

      for (int pos = 0; pos < length; pos++) {
        // Find the intersection that involves this (slot.id, pos), if any.
        Intersection? found;
        for (final ix in puzzle.intersections) {
          if ((ix.slotAId == slot.id && ix.positionInA == pos) ||
              (ix.slotBId == slot.id && ix.positionInB == pos)) {
            found = ix;
            break;
          }
        }

        if (found != null) {
          // Always use the slot-A side as the canonical key so both words
          // refer to the same tile for this shared cell.
          final key = '${found.slotAId}:${found.positionInA}';
          if (intersectionsDone.contains(key)) continue;
          intersectionsDone.add(key);
        }

        final letter = pos < word.length ? word[pos] : '?';
        tiles.add(PoolTile(id: tileId++, letter: letter));
      }
    }

    // Shuffle with a reproducible seed so the pool order doesn't reveal
    // the solution but is consistent for the same puzzle across sessions.
    tiles.shuffle(Random(puzzle.seed.hashCode));
    return tiles;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  // Public read accessor so GameScreen can get current state without
  // going through the protected StateNotifier.state field.
  GameState get currentState => state;

  // -------------------------------------------------------------------------
  // Tile placement
  // -------------------------------------------------------------------------

  /// Place [tileId] into [targetCell]. If the cell is already occupied by a
  /// different tile, that tile is displaced back to the pool.
  void placeTile(int tileId, CellKey targetCell) {
    final tiles = List<PoolTile>.from(state.tiles);

    // Displace any tile already occupying the target cell
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].id != tileId && tiles[i].placedAt == targetCell) {
        tiles[i] = tiles[i].returnToPool();
        break;
      }
    }

    // Place the moving tile at the target cell
    final movingIdx = tiles.indexWhere((t) => t.id == tileId);
    if (movingIdx == -1) return;
    tiles[movingIdx] = tiles[movingIdx].withPlacement(targetCell);

    state = state.copyWith(tiles: tiles, slotResults: const {});
  }

  /// Return [tileId] to the pool.
  void returnTile(int tileId) {
    final tiles = List<PoolTile>.from(state.tiles);
    final idx = tiles.indexWhere((t) => t.id == tileId);
    if (idx == -1) return;
    tiles[idx] = tiles[idx].returnToPool();
    state = state.copyWith(tiles: tiles, slotResults: const {});
  }

  /// Return all tiles to the pool.
  void clearAll() {
    state = state.copyWith(
      tiles: state.tiles.map((t) => t.returnToPool()).toList(),
      slotResults: const {},
    );
  }

  // -------------------------------------------------------------------------
  // Submission
  // -------------------------------------------------------------------------

  Future<void> onSubmit() async {
    if (state.phase == GamePhase.submitted) return;

    state = state.copyWith(
      phase: GamePhase.submitted,
      attemptsThisLevel: state.attemptsThisLevel + 1,
    );

    final newSlotResults = <int, SlotResult>{};
    final newSolvedWords = Map<int, String>.from(state.solvedWords);
    bool anyErrors = false;
    bool allFilled = true;

    for (final slot in state.puzzle.wordSlots) {
      // Already solved slots stay correct
      if (newSolvedWords.containsKey(slot.id)) {
        newSlotResults[slot.id] = SlotResult.correct;
        continue;
      }

      final word = state.wordForSlot(slot);
      if (word == null) {
        newSlotResults[slot.id] = SlotResult.unvalidated;
        allFilled = false;
        continue;
      }

      // Dictionary check
      final inDict = await _wordValidator(word);
      if (!mounted) return;
      if (!inDict) {
        newSlotResults[slot.id] = SlotResult.wrongWord;
        anyErrors = true;
        continue;
      }

      // Constraint check
      if (!slot.constraint.validator.validate(word)) {
        newSlotResults[slot.id] = SlotResult.wrongConstraint;
        anyErrors = true;
        continue;
      }

      // Length check
      if (slot.requiredLength != null && word.length != slot.requiredLength) {
        newSlotResults[slot.id] = SlotResult.wrongConstraint;
        anyErrors = true;
        continue;
      }

      newSlotResults[slot.id] = SlotResult.correct;
      newSolvedWords[slot.id] = word;
    }

    if (!mounted) return;

    // All complete and all correct → level complete
    if (!anyErrors && allFilled &&
        newSolvedWords.length == state.puzzle.wordSlots.length) {
      state = state.copyWith(
        phase: GamePhase.levelComplete,
        solvedWords: newSolvedWords,
        slotResults: newSlotResults,
      );
      return;
    }

    // Show per-slot feedback, auto-clear after feedbackDurationMs
    state = state.copyWith(
      phase: GamePhase.idle,
      solvedWords: newSolvedWords,
      slotResults: newSlotResults,
    );
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: GameConstants.feedbackDurationMs),
      () {
        if (!mounted) return;
        state = state.copyWith(slotResults: const {});
      },
    );
  }
}
