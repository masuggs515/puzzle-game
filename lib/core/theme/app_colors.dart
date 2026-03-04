// lib/core/theme/app_colors.dart
// Color palette for the puzzle game.
// TODO MAS: Confirm final brand colors with Adam before Phase 4 (polish).

import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors (placeholders — to be confirmed)
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF2C6FAC);
  static const Color accent = Color(0xFFFFD166);

  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2E);

  // Feedback states (per GDD)
  static const Color feedbackCorrect = Color(0xFF4CAF50);   // green — word is correct
  static const Color feedbackAmber = Color(0xFFFFC107);     // amber — real word, wrong constraint
  static const Color feedbackIncorrect = Color(0xFFF44336); // red — not a valid word

  // Feedback state aliases (from spec)
  static const Color feedbackWrongWord = feedbackIncorrect;       // red — not a word
  static const Color feedbackWrongConstraint = feedbackAmber;     // amber — wrong constraint

  // Tile states
  static const Color tileDefault = Color(0xFFE0E0E0);
  static const Color tileSelected = Color(0xFF4A90D9);
  static const Color tileLocked = Color(0xFF9E9E9E);
  static const Color tileConnected = Color(0xFF81C784); // green — locked in solved word

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnDark = Color(0xFFFFFFFF);
}
