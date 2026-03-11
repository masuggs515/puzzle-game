// lib/features/game/widgets/grid_cell_widget.dart
// Phase 4 — Core Game (tile-placement redesign)

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

/// A single cell in the crossword grid. Acts as a DragTarget for PoolTiles.
/// Intersection cells (shared between two word slots) have a distinct visual.
class GridCellWidget extends StatelessWidget {
  final CellKey cellKey;
  final PoolTile? placedTile;    // null = empty cell
  final bool isIntersection;     // true = shared by two word slots
  final SlotResult slotResult;   // feedback state for this cell's slot
  final void Function(PoolTile tile, CellKey target) onTileDropped;
  final void Function(int tileId) onTileReturned;
  final double size;

  const GridCellWidget({
    super.key,
    required this.cellKey,
    required this.placedTile,
    required this.isIntersection,
    required this.slotResult,
    required this.onTileDropped,
    required this.onTileReturned,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PoolTile>(
      onWillAcceptWithDetails: (details) => details.data.id != placedTile?.id,
      onAcceptWithDetails: (details) => onTileDropped(details.data, cellKey),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return _CellContent(
          tile: placedTile,
          isIntersection: isIntersection,
          isHovered: isHovered,
          slotResult: slotResult,
          size: size,
          onTileReturned: placedTile != null
              ? () => onTileReturned(placedTile!.id)
              : null,
        );
      },
    );
  }
}

class _CellContent extends StatelessWidget {
  final PoolTile? tile;
  final bool isIntersection;
  final bool isHovered;
  final SlotResult slotResult;
  final double size;
  final VoidCallback? onTileReturned;

  const _CellContent({
    required this.tile,
    required this.isIntersection,
    required this.isHovered,
    required this.slotResult,
    required this.size,
    required this.onTileReturned,
  });

  Color _cellColor() {
    if (tile != null) {
      switch (slotResult) {
        case SlotResult.correct:
          return AppColors.feedbackCorrect.withValues(alpha: 0.3);
        case SlotResult.wrongWord:
          return AppColors.feedbackWrongWord.withValues(alpha: 0.3);
        case SlotResult.wrongConstraint:
          return AppColors.feedbackWrongConstraint.withValues(alpha: 0.3);
        case SlotResult.unvalidated:
          return AppColors.tileSelected.withValues(alpha: 0.3);
      }
    }
    if (isHovered) return AppColors.primary.withValues(alpha: 0.25);
    return AppColors.surface.withValues(alpha: 0.5);
  }

  Color _borderColor() {
    switch (slotResult) {
      case SlotResult.correct:
        return AppColors.feedbackCorrect;
      case SlotResult.wrongWord:
        return AppColors.feedbackWrongWord;
      case SlotResult.wrongConstraint:
        return AppColors.feedbackWrongConstraint;
      case SlotResult.unvalidated:
        break;
    }
    if (isHovered) return AppColors.primary;
    if (isIntersection) return AppColors.accent;
    return Colors.white.withValues(alpha: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final letter = tile?.letter;

    final cellWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _cellColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _borderColor(),
          width: isIntersection ? 2 : 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Intersection corner mark — small triangle in top-right corner
          if (isIntersection)
            Positioned(
              top: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                ),
                child: CustomPaint(
                  size: Size(size * 0.28, size * 0.28),
                  painter: _CornerTrianglePainter(color: AppColors.accent),
                ),
              ),
            ),
          // Letter or empty indicator
          Center(
            child: letter != null
                ? Text(
                    letter.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(
                    Icons.add,
                    color:
                        Colors.white.withValues(alpha: isHovered ? 0.7 : 0.2),
                    size: size * 0.35,
                  ),
          ),
        ],
      ),
    );

    // If a tile is in this cell, make the whole cell draggable so the player
    // can move it to another cell or back to the pool.
    if (tile != null) {
      return Draggable<PoolTile>(
        data: tile,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                tile!.letter.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
        ),
        child: cellWidget,
      );
    }

    return cellWidget;
  }
}

class _CornerTrianglePainter extends CustomPainter {
  final Color color;

  const _CornerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerTrianglePainter old) => old.color != color;
}
