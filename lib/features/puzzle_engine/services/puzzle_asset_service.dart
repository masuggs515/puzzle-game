// lib/features/puzzle_engine/services/puzzle_asset_service.dart
// Phase 3 — Puzzle Engine
// Spec: flutter-agent-spec.md
//
// Loads and caches the hand-crafted puzzle JSON asset.
// Singleton so the asset is only decoded once per app lifecycle.

import 'dart:convert';

import 'package:flutter/services.dart';

class PuzzleAssetService {
  static PuzzleAssetService? _instance;
  static PuzzleAssetService get instance =>
      _instance ??= PuzzleAssetService._();
  PuzzleAssetService._();

  List<Map<String, dynamic>>? _puzzles;

  Future<List<Map<String, dynamic>>> loadHandCraftedPuzzles() async {
    if (_puzzles != null) return _puzzles!;
    final jsonStr = await rootBundle.loadString(
      'assets/puzzles/hand_crafted_001_050.json',
    );
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _puzzles = List<Map<String, dynamic>>.from(data['puzzles'] as List);
    return _puzzles!;
  }

  void clearCache() => _puzzles = null;
}
