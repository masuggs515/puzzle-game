// lib/features/game/widgets/draggable_letter_tile.dart
// Phase 4 — Core Game (tile-placement redesign)

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

/// A letter tile that can be dragged from the pool into a grid cell.
class DraggableLetterTile extends StatelessWidget {
  final PoolTile tile;
  final double size;

  const DraggableLetterTile({
    super.key,
    required this.tile,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<PoolTile>(
      data: tile,
      feedback: Material(
        color: Colors.transparent,
        child: _TileVisual(letter: tile.letter, size: size, isLifted: true),
      ),
      childWhenDragging: _TileVisual(
        letter: tile.letter,
        size: size,
        opacity: 0.25,
      ),
      child: _TileVisual(letter: tile.letter, size: size),
    );
  }
}

class _TileVisual extends StatelessWidget {
  final String letter;
  final double size;
  final bool isLifted;
  final double opacity;

  const _TileVisual({
    required this.letter,
    required this.size,
    this.isLifted = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: isLifted ? 1.1 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLifted ? AppColors.primary : AppColors.tileDefault,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLifted
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.2),
              width: isLifted ? 2 : 1.5,
            ),
            boxShadow: isLifted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
