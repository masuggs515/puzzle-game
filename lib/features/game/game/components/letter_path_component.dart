// lib/features/game/game/components/letter_path_component.dart
// Phase 4 — Core Game
// Renders the drag-path line connecting selected letter tiles.

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_game/core/theme/app_colors.dart';

class LetterPathComponent extends Component {
  final List<Vector2> _points = [];

  void startPath(Vector2 start) {
    _points.clear();
    _points.add(start.clone());
  }

  void addPoint(Vector2 point) {
    // Deduplicate points that are essentially the same position
    if (_points.isEmpty || (_points.last - point).length > 1) {
      _points.add(point.clone());
    }
  }

  void clearPath() {
    _points.clear();
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;

    final paint = Paint()
      ..color = AppColors.tileSelected.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(_points[0].x, _points[0].y);
    for (var i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].x, _points[i].y);
    }
    canvas.drawPath(path, paint);
  }
}
