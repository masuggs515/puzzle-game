// lib/features/game/widgets/draggable_letter_tile.dart
// Phase 9 — MERIDIAN design

import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';
import 'package:puzzle_game/core/theme/app_text_styles.dart';
import 'package:puzzle_game/features/game/models/game_state.dart';

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
          isHintHighlighted: false,
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
    final BoxDecoration decoration;
    final List<BoxShadow> shadows;

    if (isLifted) {
      shadows = [
        const BoxShadow(
          color: Color(0x591C1410),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
      decoration = BoxDecoration(
        color: AppColors.aged,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        border: Border.all(color: AppColors.signal, width: 1),
        boxShadow: shadows,
      );
    } else if (isHintHighlighted) {
      shadows = [
        BoxShadow(
          color: AppColors.signal.withValues(alpha: 0.35),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
      decoration = BoxDecoration(
        color: AppColors.signal.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        border: Border(
          top: const BorderSide(color: Color(0x401C1410), width: 1),
          left: const BorderSide(color: Color(0x401C1410), width: 1),
          right: const BorderSide(color: Color(0x401C1410), width: 1),
          bottom: BorderSide(color: AppColors.signal.withValues(alpha: 0.6), width: 3),
        ),
        boxShadow: shadows,
      );
    } else {
      shadows = [
        const BoxShadow(
          color: Color(0x331C1410),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
      decoration = const BoxDecoration(
        color: AppColors.aged,
        borderRadius: BorderRadius.all(Radius.circular(3)),
        border: Border(
          top: BorderSide(color: Color(0x401C1410), width: 1),
          left: BorderSide(color: Color(0x401C1410), width: 1),
          right: BorderSide(color: Color(0x401C1410), width: 1),
          bottom: BorderSide(color: Color(0x591C1410), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331C1410),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: isLifted ? 1.08 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: isLifted || isHintHighlighted
              ? decoration
              : BoxDecoration(
                  color: AppColors.aged,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  border: const Border(
                    top: BorderSide(color: Color(0x401C1410), width: 1),
                    left: BorderSide(color: Color(0x401C1410), width: 1),
                    right: BorderSide(color: Color(0x401C1410), width: 1),
                    bottom: BorderSide(color: Color(0x591C1410), width: 3),
                  ),
                  boxShadow: shadows,
                ),
          child: Center(
            child: Text(
              letter.toUpperCase(),
              style: AppTextStyles.tileLabel.copyWith(color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
