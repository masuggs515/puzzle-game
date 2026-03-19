// lib/core/widgets/graph_paper_background.dart
// Phase 9 — MERIDIAN texture system
// Wraps screen body with a parchment graph-paper texture.
// Light mode: major 20px grid + minor 4px grid.
// Dark mode: major 20px grid only, amber tint.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GraphPaperBackground extends StatelessWidget {
  final Widget child;
  final bool darkMode;
  /// Scales all grid line alpha values. 1.0 = full, 0.5 = half opacity.
  final double opacity;

  const GraphPaperBackground({
    super.key,
    required this.child,
    this.darkMode = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkMode ? AppColors.desk : AppColors.parchment,
      child: CustomPaint(
        painter: _GraphPaperPainter(darkMode: darkMode, opacity: opacity),
        child: child,
      ),
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  final bool darkMode;
  final double opacity;

  const _GraphPaperPainter({required this.darkMode, this.opacity = 1.0});

  int _a(int alpha) => (alpha * opacity).round().clamp(0, 255);

  @override
  void paint(Canvas canvas, Size size) {
    if (darkMode) {
      // Dark mode: major grid only, amber tint
      final majorPaint = Paint()
        ..color = Color.fromARGB(_a(0x12), 0xC8, 0xA8, 0x50)
        ..strokeWidth = 1.0;
      _drawGrid(canvas, size, majorPaint, 20.0);
    } else {
      // Light mode: major grid (20px) + minor grid (4px)
      final majorPaint = Paint()
        ..color = Color.fromARGB(_a(0x1F), 0x1C, 0x14, 0x10)
        ..strokeWidth = 1.0;
      final minorPaint = Paint()
        ..color = Color.fromARGB(_a(0x0A), 0x1C, 0x14, 0x10)
        ..strokeWidth = 0.5;
      _drawGrid(canvas, size, minorPaint, 4.0);
      _drawGrid(canvas, size, majorPaint, 20.0);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GraphPaperPainter old) =>
      old.darkMode != darkMode || old.opacity != opacity;
}
