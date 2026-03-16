// lib/features/game/widgets/letter_pool_widget.dart
// Phase 9 — MERIDIAN design

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';
import 'package:puzzle_game/features/game/widgets/draggable_letter_tile.dart';

/// The tile bank below the crossword grid.
/// Shows all tiles that are currently in the pool (not placed in any grid cell).
/// Also acts as a DragTarget — dropping a grid tile here returns it to the pool.
/// [hintTileIds] is a set of tile IDs to visually highlight as hint candidates.
class LetterPoolWidget extends StatelessWidget {
  final List<PoolTile> tiles;
  final Set<int> hintTileIds;
  final void Function(int tileId) onTileReturned;

  const LetterPoolWidget({
    super.key,
    required this.tiles,
    required this.onTileReturned,
    this.hintTileIds = const <int>{},
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.signal.withValues(alpha: 0.08)
                : const Color(0x0F1C1410),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isHovered
                  ? AppColors.signal.withValues(alpha: 0.3)
                  : const Color(0x1A1C1410),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '\u2592 AVAILABLE TILES',
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 8,
                    letterSpacing: 1.12,
                    color: AppColors.inkFaded,
                  ),
                ),
              ),
              poolTiles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'All tiles placed',
                          style: const TextStyle(
                            fontFamily: 'SpecialElite',
                            fontSize: 10,
                            color: AppColors.inkFaded,
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: poolTiles
                          .map(
                            (t) => DraggableLetterTile(
                              tile: t,
                              isHintHighlighted: hintTileIds.contains(t.id),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
        );
      },
    );
  }
}
