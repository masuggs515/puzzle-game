// lib/features/game/game/puzzle_game.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Game State Machine
//
// Flame game that renders the letter tile grid and drag path.
// All game logic lives in GameNotifier; this class handles rendering
// and translates raw Flame drag events into notifier calls.

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/game/components/letter_path_component.dart';
import 'package:puzzle_game/features/game/game/components/letter_tile_component.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/providers/game_provider.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

class PuzzleGame extends FlameGame with DragCallbacks {
  final Puzzle puzzle;
  final GameNotifier notifier;
  final GameState Function() getState;

  PuzzleGame({
    required this.puzzle,
    required this.notifier,
    required this.getState,
  });

  late List<LetterTileComponent> tiles;
  late LetterPathComponent pathComponent;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildTiles();
    pathComponent = LetterPathComponent();
    add(pathComponent);
  }

  void _buildTiles() {
    const double tileSize = 56.0;
    const double gap = 8.0;
    final letters = puzzle.letterPool;
    final cols = _columnsForCount(letters.length);

    final totalWidth = cols * (tileSize + gap) - gap;
    final startX = (size.x - totalWidth) / 2;
    final startY = size.y * 0.15;

    tiles = [];
    for (var i = 0; i < letters.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final x = startX + col * (tileSize + gap);
      final y = startY + row * (tileSize + gap);

      final tile = LetterTileComponent(
        letter: letters[i],
        index: i,
        position: Vector2(x, y),
        size: Vector2.all(tileSize),
      );
      tiles.add(tile);
      add(tile);
    }
  }

  int _columnsForCount(int count) {
    if (count <= 6) return count;
    if (count <= 12) return 6;
    return 8;
  }

  LetterTileComponent? _tileAtPosition(Vector2 position) {
    for (final tile in tiles) {
      if (tile.hitTest(position)) return tile;
    }
    return null;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // canvasPosition is in the game-widget coordinate space
    final tile = _tileAtPosition(event.canvasPosition);
    if (tile != null) {
      notifier.onTileDragStart(tile.index);
      tile.setSelected(true);
      pathComponent.startPath(tile.center);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // canvasEndPosition is the current finger position (end of this delta)
    final tile = _tileAtPosition(event.canvasEndPosition);
    final currentState = getState();
    if (tile != null && !currentState.currentPath.contains(tile.index)) {
      notifier.onTileDragEnter(tile.index);
      tile.setSelected(true);
      pathComponent.addPoint(tile.center);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    notifier.onTileDragEnd();
  }

  /// Called from GameScreen on every state change to sync tile visuals.
  void syncState(GameState gameState) {
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      tile.isInCurrentPath = gameState.currentPath.contains(i);
      tile.isHinted = gameState.hintedTileIndices.contains(i);
      tile.isLocked = _isTileLocked(i, gameState);
    }

    if (gameState.currentPath.isEmpty) {
      pathComponent.clearPath();
    }
  }

  bool _isTileLocked(int tileIndex, GameState gameState) {
    // TODO Phase 5: map tiles to word positions and lock solved tiles.
    return false;
  }
}
