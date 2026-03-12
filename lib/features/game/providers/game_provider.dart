// lib/features/game/providers/game_provider.dart
// Phase 5 — Economy & Progression (extended from Phase 4)
// Spec: flutter-agent-spec.md § Game State Machine
//
// Async puzzle loader + synchronous game state notifier.
// No code generation — plain StateNotifier / FutureProvider.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

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
// Callback typedefs injected into GameNotifier.
// Using callbacks instead of storing WidgetRef (which cannot be held in a
// StateNotifier) or importing SupabaseService directly (avoids circular deps
// and keeps GameNotifier testable in isolation).
// ---------------------------------------------------------------------------

typedef WordValidator = Future<bool> Function(String word);
typedef EdgeFunctionCaller = Future<Map<String, dynamic>> Function(
  String functionName,
  Map<String, dynamic> body,
);
typedef ProfileIdGetter = Future<String?> Function();

// ---------------------------------------------------------------------------
// GameNotifier — owns all mutable game state for one play-through.
// Created as local state in GameScreen.
// ---------------------------------------------------------------------------

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier({
    required Puzzle puzzle,
    required WordValidator wordValidator,
    EdgeFunctionCaller? callEdgeFunction,
    ProfileIdGetter? getProfileId,
  })  : _wordValidator = wordValidator,
        _callEdgeFunction = callEdgeFunction,
        _getProfileId = getProfileId,
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
  final EdgeFunctionCaller? _callEdgeFunction;
  final ProfileIdGetter? _getProfileId;
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

  /// Place [tileId] into [targetCell].
  ///
  /// - Grid → occupied grid: swap the two tiles (both stay on the grid).
  /// - Pool → occupied grid: displaced tile returns to the pool.
  /// - Any → empty grid: place normally.
  void placeTile(int tileId, CellKey targetCell) {
    final tiles = List<PoolTile>.from(state.tiles);

    final movingIdx = tiles.indexWhere((t) => t.id == tileId);
    if (movingIdx == -1) return;

    final movingTile = tiles[movingIdx];
    final movingFrom = movingTile.placedAt; // null if coming from pool

    // Find any tile already at the target cell.
    final occupantIdx =
        tiles.indexWhere((t) => t.id != tileId && t.placedAt == targetCell);

    if (occupantIdx != -1) {
      if (movingFrom != null) {
        // Grid → occupied grid: swap.
        tiles[occupantIdx] = tiles[occupantIdx].withPlacement(movingFrom);
      } else {
        // Pool → occupied grid: displaced tile returns to pool.
        tiles[occupantIdx] = tiles[occupantIdx].returnToPool();
      }
    }

    tiles[movingIdx] = movingTile.withPlacement(targetCell);

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
  // Submission — order-agnostic validation
  //
  // Validation is holistic across all placed words:
  //   1. All slots must be filled.
  //   2. Every placed word must be in the dictionary.
  //   3. Every placed word must satisfy at least one of the puzzle's constraints.
  //   4. Every constraint must be satisfied by at least one placed word.
  // Intersection consistency is guaranteed by the tile-placement model
  // (one tile per cell, so shared letters are always the same).
  // -------------------------------------------------------------------------

  Future<void> onSubmit() async {
    if (state.phase == GamePhase.submitted) return;

    state = state.copyWith(
      phase: GamePhase.submitted,
      attemptsThisLevel: state.attemptsThisLevel + 1,
    );

    final slots = state.puzzle.wordSlots;

    // 1. Collect placed words — return to idle silently if any slot is empty.
    final placed = <int, String>{}; // slotId → word
    for (final slot in slots) {
      final word = state.wordForSlot(slot);
      if (word == null) {
        state = state.copyWith(phase: GamePhase.idle, slotResults: const {});
        return;
      }
      placed[slot.id] = word;
    }

    // 2. Dictionary check — every word must be a recognised word.
    final dictFail = <int>{};
    for (final slot in slots) {
      final inDict = await _wordValidator(placed[slot.id]!);
      if (!mounted) return;
      if (!inDict) dictFail.add(slot.id);
    }

    if (dictFail.isNotEmpty) {
      final badWords = dictFail
          .map((id) => placed[id]!.toUpperCase())
          .join(', ');
      final verb = dictFail.length == 1 ? "isn't" : "aren't";
      _showFeedback(
        results: {
          for (final slot in slots)
            slot.id: dictFail.contains(slot.id)
                ? SlotResult.wrongWord
                : SlotResult.unvalidated,
        },
        message: FeedbackMessage(
          type: FeedbackType.wrongWord,
          message: 'Not a valid word',
          constraintText: '$badWords $verb in the dictionary',
        ),
      );
      return;
    }

    // 3 & 4. Order-agnostic constraint check.
    final words = placed.values.toList();
    final constraints = slots.map((s) => s.constraint).toList();

    final allWordsSatisfySome = words.every(
      (w) => constraints.any((c) => c.validator.validate(w)),
    );
    final allConstraintsCovered = constraints.every(
      (c) => words.any((w) => c.validator.validate(w)),
    );

    if (!allWordsSatisfySome) {
      // Find which words fail every constraint.
      final badWords = placed.entries
          .where((e) => !constraints.any((c) => c.validator.validate(e.value)))
          .map((e) => e.value.toUpperCase())
          .join(', ');
      _showFeedback(
        results: {
          for (final slot in slots)
            slot.id: constraints.any(
                    (c) => c.validator.validate(placed[slot.id]!))
                ? SlotResult.unvalidated
                : SlotResult.wrongConstraint,
        },
        message: FeedbackMessage(
          type: FeedbackType.wrongConstraint,
          message: 'Wrong',
          constraintText: "$badWords doesn't fit any of the categories",
        ),
      );
      return;
    }

    if (!allConstraintsCovered) {
      // All words are individually valid but the set doesn't cover every constraint.
      final uncovered = constraints
          .where((c) => !words.any((w) => c.validator.validate(w)))
          .map((c) => c.displayText)
          .join(', ');
      _showFeedback(
        results: {for (final slot in slots) slot.id: SlotResult.wrongConstraint},
        message: FeedbackMessage(
          type: FeedbackType.wrongConstraint,
          message: 'Wrong',
          constraintText: 'No word satisfies: $uncovered',
        ),
      );
      return;
    }

    // All checks passed — level complete.
    state = state.copyWith(
      phase: GamePhase.levelComplete,
      solvedWords: placed,
      slotResults: {for (final slot in slots) slot.id: SlotResult.correct},
    );
  }

  void _showFeedback({
    required Map<int, SlotResult> results,
    required FeedbackMessage message,
  }) {
    state = state.copyWith(
      phase: GamePhase.idle,
      slotResults: results,
      feedbackMessage: message,
    );
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: GameConstants.feedbackDurationMs),
      () {
        if (!mounted) return;
        state = state.copyWith(
          slotResults: const {},
          clearFeedbackMessage: true,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Backend integration — Phase 5
  // -------------------------------------------------------------------------

  /// Called by GameScreen when the levelComplete phase is detected.
  /// Calls the on-level-complete Edge Function and returns the result.
  /// Returns default values (coinsEarned: 0) if backend is unavailable.
  Future<({int coinsEarned, List<String> achievementsUnlocked, int newBalance})>
      onLevelCompletedBackend({
    required int levelNumber,
    required bool isBoss,
  }) async {
    const defaults = (
      coinsEarned: 0,
      achievementsUnlocked: <String>[],
      newBalance: 0
    );

    final caller = _callEdgeFunction;
    final profileIdGetter = _getProfileId;
    if (caller == null || profileIdGetter == null) return defaults;

    try {
      final profileId = await profileIdGetter();
      if (profileId == null) return defaults;

      final levelType = isBoss ? 'bossLevel' : 'standard';
      final idempotencyKey = '$profileId:$levelNumber:$levelType';

      final result = await caller('on-level-complete', {
        'level_number': levelNumber,
        'level_type': levelType,
        'hints_used': state.hintsUsedThisLevel,
        'attempts_made': state.attemptsThisLevel,
        'words_found': state.solvedWords.length,
        'time_taken_ms': DateTime.now()
            .difference(state.levelStartTime)
            .inMilliseconds,
        'stars': state.stars,
        'idempotency_key': idempotencyKey,
      });

      final coinsAwarded = (result['coins_awarded'] as num?)?.toInt() ?? 0;
      final newBalance = (result['new_balance'] as num?)?.toInt() ?? 0;
      final achievements =
          (result['achievements_unlocked'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

      return (
        coinsEarned: coinsAwarded,
        achievementsUnlocked: achievements,
        newBalance: newBalance
      );
    } catch (e, st) {
      debugPrint('[GameNotifier] onLevelCompletedBackend error: $e\n$st');
      return defaults;
    }
  }

  /// Requests a hint for the first unsolved slot.
  /// Calls on-hint-used Edge Function to deduct coins server-side.
  /// Returns true if hint was granted.
  Future<bool> onHintRequested({required int coinBalance}) async {
    if (coinBalance < GameConstants.hintCost) return false;
    if (state.hintsUsedThisLevel >= GameConstants.maxHintsPerLevel) {
      return false;
    }

    // Find first unsolved slot.
    final unsolvedSlot = state.puzzle.wordSlots
        .where((s) => !state.solvedWords.containsKey(s.id))
        .firstOrNull;
    if (unsolvedSlot == null) return false;

    final caller = _callEdgeFunction;
    final profileIdGetter = _getProfileId;

    if (caller != null && profileIdGetter != null) {
      try {
        final profileId = await profileIdGetter();
        if (profileId != null) {
          final idempotencyKey =
              '$profileId:hint:${state.puzzle.levelNumber ?? 0}:${unsolvedSlot.id}:${state.hintsUsedThisLevel}';
          final result = await caller('on-hint-used', {
            'level_number': state.puzzle.levelNumber ?? 0,
            'word_slot_id': unsolvedSlot.id,
            'idempotency_key': idempotencyKey,
          });
          if (result['success'] != true) return false;
        }
      } catch (e, st) {
        debugPrint('[GameNotifier] onHintRequested backend error: $e\n$st');
        // If backend fails, allow hint anyway (offline mode).
      }
    }

    // Locally compute hint: highlight pool tiles whose letters appear in the
    // unsolved word.
    final targetWord = unsolvedSlot.assignedWord ?? '';
    final hintLetters = targetWord.toUpperCase().split('').toSet();

    state = state.copyWith(
      hintTileIds: state.tiles
          .where((t) =>
              t.placedAt == null &&
              hintLetters.contains(t.letter.toUpperCase()))
          .map((t) => t.id)
          .toSet(),
      hintsUsedThisLevel: state.hintsUsedThisLevel + 1,
      feedbackMessage: FeedbackMessage(
        type: FeedbackType.hint,
        message: 'Hint',
        constraintText: 'Look for: "${unsolvedSlot.constraint.displayText}"',
      ),
    );

    // Clear hint highlights after 3 seconds.
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      state = state.copyWith(
        clearHintTileIds: true,
        clearFeedbackMessage: true,
        slotResults: const {},
      );
    });

    return true;
  }

  /// Requests a skip for the current level.
  /// Calls on-level-skip Edge Function to deduct 50 coins.
  /// Returns a record with { success, newBalance }.
  Future<({bool success, int newBalance})> onSkipRequested({
    required int coinBalance,
  }) async {
    if (coinBalance < GameConstants.skipCost) {
      return (success: false, newBalance: coinBalance);
    }

    final caller = _callEdgeFunction;
    final profileIdGetter = _getProfileId;

    if (caller != null && profileIdGetter != null) {
      try {
        final profileId = await profileIdGetter();
        if (profileId != null) {
          final levelNumber = state.puzzle.levelNumber ?? 0;
          final levelType = state.puzzle.isBoss ? 'bossLevel' : 'standard';
          final idempotencyKey = '$profileId:skip:$levelNumber';

          final result = await caller('on-level-skip', {
            'level_number': levelNumber,
            'level_type': levelType,
            'idempotency_key': idempotencyKey,
          });

          if (result['success'] != true) {
            return (success: false, newBalance: coinBalance);
          }
          final newBalance = (result['new_balance'] as num?)?.toInt() ?? 0;
          return (success: true, newBalance: newBalance);
        }
      } catch (e, st) {
        debugPrint('[GameNotifier] onSkipRequested backend error: $e\n$st');
        // Fall through to optimistic local deduction.
      }
    }

    // Offline fallback — optimistic local deduction.
    return (success: true, newBalance: coinBalance - GameConstants.skipCost);
  }
}
