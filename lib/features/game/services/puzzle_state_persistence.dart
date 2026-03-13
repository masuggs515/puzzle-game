// lib/features/game/services/puzzle_state_persistence.dart
// Phase 5 — Local puzzle state persistence
// Spec: flutter-agent-spec.md § Game State Machine
//
// Saves and restores tile placements to/from shared_preferences so a player
// can leave a level mid-puzzle and resume where they left off.
// Supabase is never called from this service — only local storage.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

/// The data that gets persisted between sessions for a single level.
class SavedPuzzleState {
  final Map<int, CellKey> placements; // tileId → CellKey
  final int hintsUsed;
  final int attempts;

  const SavedPuzzleState({
    required this.placements,
    required this.hintsUsed,
    required this.attempts,
  });
}

/// Pure static service. No Flutter widget deps.
/// Key format: `puzzle_state_v1_level_$levelNumber`
class PuzzleStatePersistence {
  static String _key(int levelNumber) => 'puzzle_state_v1_level_$levelNumber';

  /// Loads a previously saved puzzle state for [levelNumber].
  /// Returns null if nothing is saved or if the saved data is corrupt.
  static Future<SavedPuzzleState?> load(int levelNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key(levelNumber));
      if (json == null) return null;
      final data = jsonDecode(json) as Map<String, dynamic>;
      final rawPlacements = data['placements'] as List<dynamic>? ?? [];
      final placements = <int, CellKey>{};
      for (final p in rawPlacements) {
        final tileId = (p['tile_id'] as num).toInt();
        final slotId = (p['slot_id'] as num).toInt();
        final pos = (p['pos'] as num).toInt();
        placements[tileId] = CellKey(slotId: slotId, positionInSlot: pos);
      }
      return SavedPuzzleState(
        placements: placements,
        hintsUsed: (data['hints_used'] as num?)?.toInt() ?? 0,
        attempts: (data['attempts'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[PuzzleStatePersistence] load error: $e');
      return null;
    }
  }

  /// Persists the current tile placements, hints used, and attempt count
  /// for [levelNumber] so the player can resume mid-puzzle.
  static Future<void> save(
    int levelNumber,
    List<PoolTile> tiles,
    int hintsUsed,
    int attempts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final placements = <Map<String, int>>[];
      for (final tile in tiles) {
        if (tile.placedAt != null) {
          placements.add({
            'tile_id': tile.id,
            'slot_id': tile.placedAt!.slotId,
            'pos': tile.placedAt!.positionInSlot,
          });
        }
      }
      await prefs.setString(
        _key(levelNumber),
        jsonEncode({
          'placements': placements,
          'hints_used': hintsUsed,
          'attempts': attempts,
        }),
      );
    } catch (e) {
      debugPrint('[PuzzleStatePersistence] save error: $e');
    }
  }

  /// Removes any saved state for [levelNumber].
  /// Called on level completion and on skip so stale data is not restored
  /// if the player replays the level.
  static Future<void> clear(int levelNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(levelNumber));
    } catch (e) {
      debugPrint('[PuzzleStatePersistence] clear error: $e');
    }
  }
}
