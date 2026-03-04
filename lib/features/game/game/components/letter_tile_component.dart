// lib/features/game/game/components/letter_tile_component.dart
// Phase 4 — Core Game
// Spec: flutter-agent-spec.md § Game State Machine
//
// A single letter tile rendered inside the Flame game canvas.
// Visual state (selected / hinted / locked) is synced from GameScreen
// via PuzzleGame.syncState().

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';

class LetterTileComponent extends PositionComponent {
  final String letter;
  final int index;
  bool isInCurrentPath = false;
  bool isLocked = false;
  bool isHinted = false;

  LetterTileComponent({
    required this.letter,
    required this.index,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  /// Centre of this tile in parent coordinates.
  @override
  Vector2 get center => Vector2(position.x + size.x / 2, position.y + size.y / 2);

  @override
  void render(Canvas canvas) {
    final Color tileColor;
    if (isLocked) {
      tileColor = AppColors.tileConnected;
    } else if (isHinted) {
      tileColor = AppColors.accent.withValues(alpha: 0.6);
    } else if (isInCurrentPath) {
      tileColor = AppColors.tileSelected;
    } else {
      tileColor = AppColors.tileDefault;
    }

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Fill
    canvas.drawRRect(rrect, Paint()..color = tileColor);

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter.toUpperCase(),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: size.x * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  void setSelected(bool selected) {
    isInCurrentPath = selected;
  }

  /// Returns true when [point] (in parent/game-world coordinates) lies within
  /// this tile's axis-aligned bounding box.
  bool hitTest(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}
