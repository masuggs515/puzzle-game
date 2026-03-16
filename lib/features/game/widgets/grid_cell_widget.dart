// lib/features/game/widgets/grid_cell_widget.dart
// Phase 9 — MERIDIAN design

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/core/theme/app_text_styles.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

/// A single cell in the crossword grid. Acts as a DragTarget for PoolTiles.
/// Intersection cells (shared between two word slots) have a distinct visual.
class GridCellWidget extends StatelessWidget {
  final CellKey cellKey;
  final PoolTile? placedTile;
  final bool isIntersection;
  final SlotResult slotResult;
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

  (Color bg, Border border) _decoration() {
    if (tile != null) {
      switch (slotResult) {
        case SlotResult.correct:
          return (
            AppColors.verdigris,
            Border.all(color: AppColors.verdigris),
          );
        case SlotResult.wrongWord:
        case SlotResult.wrongConstraint:
          return (
            const Color(0x268B3A1E),
            Border.all(color: AppColors.rust, width: 1),
          );
        case SlotResult.unvalidated:
          if (isIntersection) {
            return (
              const Color(0x26C8651A),
              Border.all(color: AppColors.signal, width: 2),
            );
          }
          return (
            const Color(0x14C8651A),
            Border.all(color: AppColors.signal, width: 1),
          );
      }
    }
    // Empty cell
    if (isHovered) {
      return (
        const Color(0x14C8651A),
        Border.all(color: AppColors.signal),
      );
    }
    if (isIntersection) {
      return (
        const Color(0x0FC8651A),
        Border.all(color: Color(0x66C8651A), style: BorderStyle.none),
      );
    }
    return (
      const Color(0x0A1C1410),
      Border.all(color: Color(0x1F1C1410)),
    );
  }

  Color _letterColor() {
    switch (slotResult) {
      case SlotResult.correct:
        return AppColors.parchment;
      case SlotResult.wrongWord:
      case SlotResult.wrongConstraint:
        return AppColors.rust;
      case SlotResult.unvalidated:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = tile?.letter;
    final (bg, border) = _decoration();

    // Intersection empty cells get a dashed border
    final bool useDashedBorder =
        tile == null && isIntersection && slotResult == SlotResult.unvalidated && !isHovered;

    final cellWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        border: useDashedBorder ? null : border,
      ),
      child: useDashedBorder
          ? CustomPaint(
              painter: _DashedBorderPainter(),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(size * 0.28, size * 0.28),
                      painter: _CornerTrianglePainter(color: AppColors.tungsten),
                    ),
                  ),
                  const Center(child: SizedBox.shrink()),
                ],
              ),
            )
          : Stack(
              children: [
                if (isIntersection)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(size * 0.28, size * 0.28),
                      painter: _CornerTrianglePainter(color: AppColors.tungsten),
                    ),
                  ),
                Center(
                  child: letter != null
                      ? Text(
                          letter.toUpperCase(),
                          style: AppTextStyles.tileLabel
                              .copyWith(color: _letterColor()),
                        )
                      : null,
                ),
              ],
            ),
    );

    if (tile != null) {
      return Draggable<PoolTile>(
        data: tile,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.aged,
              borderRadius: const BorderRadius.all(Radius.circular(3)),
              border: Border.all(color: AppColors.signal),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x591C1410),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                tile!.letter.toUpperCase(),
                style: AppTextStyles.tileLabel.copyWith(color: AppColors.ink),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.parchment.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: Border.all(color: const Color(0x1F1C1410)),
          ),
        ),
        child: cellWidget,
      );
    }

    return cellWidget;
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66C8651A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(3),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final segLen = draw ? dash : gap;
        if (draw) {
          final startTangent = metric.getTangentForOffset(dist);
          final endDist = (dist + segLen).clamp(0.0, metric.length);
          final endTangent = metric.getTangentForOffset(endDist);
          if (startTangent != null && endTangent != null) {
            canvas.drawLine(startTangent.position, endTangent.position, paint);
          }
        }
        dist += segLen;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter _) => false;
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
