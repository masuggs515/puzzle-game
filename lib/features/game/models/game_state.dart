// lib/features/game/models/game_state.dart
// Phase 4 — Core Game (tile-placement redesign)
// Spec: flutter-agent-spec.md § Game State Machine

import 'package:puzzle_game/core/constants/game_constants.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

enum GamePhase {
  loading,
  idle,
  submitted,
  feedbackCorrect,
  feedbackWrongWord,
  feedbackWrongConstraint,
  hintActive,
  levelComplete,
  paused,
}

enum FeedbackType { correct, wrongWord, wrongConstraint, hint }

/// Which grid cell a tile is placed in.
/// Identifies a specific letter position within a specific word slot.
class CellKey {
  final int slotId;
  final int positionInSlot;

  const CellKey({required this.slotId, required this.positionInSlot});

  @override
  bool operator ==(Object other) =>
      other is CellKey &&
      slotId == other.slotId &&
      positionInSlot == other.positionInSlot;

  @override
  int get hashCode => Object.hash(slotId, positionInSlot);

  @override
  String toString() => 'CellKey($slotId, $positionInSlot)';
}

/// A letter tile. Can be in the pool (placedAt == null) or in a grid cell.
class PoolTile {
  final int id;
  final String letter;
  final CellKey? placedAt;

  const PoolTile({required this.id, required this.letter, this.placedAt});

  PoolTile withPlacement(CellKey cell) =>
      PoolTile(id: id, letter: letter, placedAt: cell);

  PoolTile returnToPool() =>
      PoolTile(id: id, letter: letter, placedAt: null);

  bool get isInPool => placedAt == null;
}

/// Per-slot validation result, shown after submit.
enum SlotResult { unvalidated, correct, wrongWord, wrongConstraint }

class FeedbackMessage {
  final FeedbackType type;
  final String message;
  final String? constraintText;

  const FeedbackMessage({
    required this.type,
    required this.message,
    this.constraintText,
  });
}

class GameState {
  final GamePhase phase;
  final Puzzle puzzle;
  final Map<int, String> solvedWords;       // slotId → confirmed correct word
  final List<PoolTile> tiles;              // all tiles (pool + placed)
  final Map<int, SlotResult> slotResults; // per-slot feedback after submit
  final int hintsUsedThisLevel;
  final int attemptsThisLevel;
  final FeedbackMessage? feedbackMessage;
  final DateTime levelStartTime;
  final int coinBalance;
  final Set<int> hintTileIds; // tile IDs to highlight as hint candidates

  const GameState({
    required this.phase,
    required this.puzzle,
    required this.solvedWords,
    required this.tiles,
    required this.slotResults,
    required this.hintsUsedThisLevel,
    required this.attemptsThisLevel,
    required this.feedbackMessage,
    required this.levelStartTime,
    required this.coinBalance,
    this.hintTileIds = const <int>{},
  });

  /// Returns the tile placed at [cell], or null if the cell is empty.
  PoolTile? tileAt(CellKey cell) {
    for (final t in tiles) {
      if (t.placedAt == cell) return t;
    }
    return null;
  }

  /// Returns the word assembled for [slot], or null if any cell is empty.
  ///
  /// Intersection cells are stored under whichever slot's key the grid used
  /// as the drop target (always slot A's key). If a direct lookup misses, we
  /// consult [puzzle.intersections] to find the alternate CellKey and retry.
  String? wordForSlot(WordSlot slot) {
    final length = slot.requiredLength;
    if (length == null) return null;
    final buf = StringBuffer();
    for (int i = 0; i < length; i++) {
      PoolTile? tile = tileAt(CellKey(slotId: slot.id, positionInSlot: i));

      // If not found, check whether this position is an intersection cell and
      // the tile was stored under the other slot's CellKey.
      if (tile == null) {
        for (final ix in puzzle.intersections) {
          CellKey? altKey;
          if (ix.slotAId == slot.id && ix.positionInA == i) {
            altKey = CellKey(slotId: ix.slotBId, positionInSlot: ix.positionInB);
          } else if (ix.slotBId == slot.id && ix.positionInB == i) {
            altKey = CellKey(slotId: ix.slotAId, positionInSlot: ix.positionInA);
          }
          if (altKey != null) {
            tile = tileAt(altKey);
            break;
          }
        }
      }

      if (tile == null) return null;
      buf.write(tile.letter);
    }
    return buf.toString();
  }

  /// True when all word slots are solved.
  bool get isComplete => solvedWords.length == puzzle.wordSlots.length;

  /// Star rating: 3 = no hints, 2 = 1-2 hints, 1 = more hints used.
  int get stars {
    if (hintsUsedThisLevel <= GameConstants.threeStarMaxHints) return 3;
    if (hintsUsedThisLevel <= GameConstants.twoStarMaxHints) return 2;
    return 1;
  }

  GameState copyWith({
    GamePhase? phase,
    Puzzle? puzzle,
    Map<int, String>? solvedWords,
    List<PoolTile>? tiles,
    Map<int, SlotResult>? slotResults,
    int? hintsUsedThisLevel,
    int? attemptsThisLevel,
    FeedbackMessage? feedbackMessage,
    bool clearFeedbackMessage = false,
    DateTime? levelStartTime,
    int? coinBalance,
    Set<int>? hintTileIds,
    bool clearHintTileIds = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      puzzle: puzzle ?? this.puzzle,
      solvedWords: solvedWords ?? this.solvedWords,
      tiles: tiles ?? this.tiles,
      slotResults: slotResults ?? this.slotResults,
      hintsUsedThisLevel: hintsUsedThisLevel ?? this.hintsUsedThisLevel,
      attemptsThisLevel: attemptsThisLevel ?? this.attemptsThisLevel,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      levelStartTime: levelStartTime ?? this.levelStartTime,
      coinBalance: coinBalance ?? this.coinBalance,
      hintTileIds:
          clearHintTileIds ? const <int>{} : (hintTileIds ?? this.hintTileIds),
    );
  }
}
