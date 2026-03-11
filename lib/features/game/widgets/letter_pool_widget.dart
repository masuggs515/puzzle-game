// lib/features/game/widgets/letter_pool_widget.dart
// Phase 4 — Core Game (tile-placement redesign)

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/widgets/draggable_letter_tile.dart';

/// The tile bank below the crossword grid.
/// Shows all tiles that are currently in the pool (not placed in any grid cell).
/// Also acts as a DragTarget — dropping a grid tile here returns it to the pool.
class LetterPoolWidget extends StatelessWidget {
  final List<PoolTile> tiles;
  final void Function(int tileId) onTileReturned;

  const LetterPoolWidget({
    super.key,
    required this.tiles,
    required this.onTileReturned,
  });

  @override
  Widget build(BuildContext context) {
    final poolTiles = tiles.where((t) => t.isInPool).toList();

    return DragTarget<PoolTile>(
      onWillAcceptWithDetails: (details) => !details.data.isInPool,
      onAcceptWithDetails: (details) => onTileReturned(details.data.id),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: poolTiles.isEmpty
              ? Center(
                  child: Text(
                    'All tiles placed',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: poolTiles
                      .map((t) => DraggableLetterTile(tile: t))
                      .toList(),
                ),
        );
      },
    );
  }
}
