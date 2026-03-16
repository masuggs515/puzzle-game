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

  const GraphPaperBackground({
    super.key,
    required this.child,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkMode ? AppColors.desk : AppColors.parchment,
      child: CustomPaint(
        painter: _GraphPaperPainter(darkMode: darkMode),
        child: child,
      ),
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  final bool darkMode;

  const _GraphPaperPainter({required this.darkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (darkMode) {
      // Dark mode: major grid only, amber tint
      final majorPaint = Paint()
        ..color = const Color(0x12C8A850)
        ..strokeWidth = 1.0;
      _drawGrid(canvas, size, majorPaint, 20.0);
    } else {
      // Light mode: major grid (20px) + minor grid (4px)
      final majorPaint = Paint()
        ..color = const Color(0x1F1C1410)
        ..strokeWidth = 1.0;
      final minorPaint = Paint()
        ..color = const Color(0x0A1C1410)
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
  bool shouldRepaint(_GraphPaperPainter old) => old.darkMode != darkMode;
}
