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

    final json1 = await rootBundle.loadString(
      'assets/puzzles/hand_crafted_001_050.json',
    );
    final data1 = json.decode(json1) as Map<String, dynamic>;
    final list1 = List<Map<String, dynamic>>.from(data1['puzzles'] as List);

    final json2 = await rootBundle.loadString(
      'assets/puzzles/hand_crafted_051_100.json',
    );
    final data2 = json.decode(json2) as Map<String, dynamic>;
    final list2 = List<Map<String, dynamic>>.from(data2['puzzles'] as List);

    _puzzles = [...list1, ...list2];
    return _puzzles!;
  }

  void clearCache() => _puzzles = null;
}
