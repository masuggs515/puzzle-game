// lib/features/game/widgets/draggable_letter_tile.dart
// Phase 5 — Economy & Progression (extended from Phase 4)

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

/// A letter tile that can be dragged from the pool into a grid cell.
/// [isHintHighlighted] adds a golden glow to indicate this tile is a hint
/// candidate for the first unsolved word slot.
class DraggableLetterTile extends StatelessWidget {
  final PoolTile tile;
  final double size;
  final bool isHintHighlighted;

  const DraggableLetterTile({
    super.key,
    required this.tile,
    this.size = 52,
    this.isHintHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<PoolTile>(
      data: tile,
      feedback: Material(
        color: Colors.transparent,
        child: _TileVisual(
          letter: tile.letter,
          size: size,
          isLifted: true,
          isHintHighlighted: false, // no glow while dragging
        ),
      ),
      childWhenDragging: _TileVisual(
        letter: tile.letter,
        size: size,
        opacity: 0.25,
        isHintHighlighted: false,
      ),
      child: _TileVisual(
        letter: tile.letter,
        size: size,
        isHintHighlighted: isHintHighlighted,
      ),
    );
  }
}

class _TileVisual extends StatelessWidget {
  final String letter;
  final double size;
  final bool isLifted;
  final double opacity;
  final bool isHintHighlighted;

  const _TileVisual({
    required this.letter,
    required this.size,
    this.isLifted = false,
    this.opacity = 1.0,
    this.isHintHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows;
    if (isLifted) {
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isHintHighlighted) {
      shadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.7),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ];
    } else {
      shadows = const [];
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: isLifted ? 1.1 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLifted
                ? AppColors.primary
                : isHintHighlighted
                    ? AppColors.accent.withValues(alpha: 0.25)
                    : AppColors.tileDefault,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLifted
                  ? AppColors.primary
                  : isHintHighlighted
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.2),
              width: isLifted || isHintHighlighted ? 2 : 1.5,
            ),
            boxShadow: shadows.isEmpty ? null : shadows,
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
