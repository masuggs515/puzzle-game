// lib/features/game/providers/puzzle_repository_provider.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Supabase Service Patterns
//
// Riverpod provider for loading and caching puzzle data.
// Uses PuzzleAssetService (already a singleton) to load the JSON asset,
// then deserializes with PuzzleSerializer + ConstraintLibrary.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_game/features/puzzle_engine/services/puzzle_asset_service.dart';
import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/serialization/puzzle_serializer.dart';

final puzzleRepositoryProvider = Provider<PuzzleRepository>(
  (ref) => PuzzleRepository(),
);

class PuzzleRepository {
  List<Puzzle>? _cachedPuzzles;

  Future<List<Puzzle>> _loadAll() async {
    if (_cachedPuzzles != null) return _cachedPuzzles!;

    final rawList = await PuzzleAssetService.instance.loadHandCraftedPuzzles();

    // Build library without validWords — constraints that require dictionary
    // validation will pass through; word validation happens separately via
    // validWordSetProvider.
    final library = ConstraintLibrary.build();
    final serializer = PuzzleSerializer(library: library);

    _cachedPuzzles =
        rawList.map((map) => serializer.fromJson(map)).toList();
    return _cachedPuzzles!;
  }

  /// Returns the puzzle for [levelNumber]. Level numbers are 1-based.
  /// Falls back to the first puzzle if the level is not found.
  Future<Puzzle> getPuzzleByLevel(int levelNumber) async {
    final puzzles = await _loadAll();

    // Try by levelNumber field first (hand-crafted puzzles have this set)
    final byLevel = puzzles.where((p) => p.levelNumber == levelNumber).toList();
    if (byLevel.isNotEmpty) return byLevel.first;

    // Fall back to index (levelNumber - 1)
    final index = (levelNumber - 1).clamp(0, puzzles.length - 1);
    return puzzles[index];
  }

  void clearCache() {
    _cachedPuzzles = null;
    PuzzleAssetService.instance.clearCache();
  }
}
