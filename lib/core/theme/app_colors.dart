// lib/core/theme/app_colors.dart
// Phase 9 — MERIDIAN design language for Intercept.
import 'package:flutter/material.dart';

class AppColors {
  // ── Light mode — Parchment ──────────────────────────────────────────────
  static const parchment   = Color(0xFFD4C9A8); // primary background
  static const aged        = Color(0xFFC2B48A); // secondary surfaces, tile bg
  static const deepAged    = Color(0xFFA89060); // borders, dividers
  static const ink         = Color(0xFF1C1410); // primary text
  static const inkFaded    = Color(0xFF3D2E1E); // secondary text
  static const signal      = Color(0xFFC8651A); // primary accent, CTAs
  static const signalDim   = Color(0xFF7A3D10); // muted accent
  static const rust        = Color(0xFF8B3A1E); // destructive / error
  static const tungsten    = Color(0xFFE8C87A); // highlights / stars
  static const verdigris   = Color(0xFF2A5C4E); // correct/confirmed
  static const desk        = Color(0xFF2C1F0E); // app shell / dark bg
  static const gridLine    = Color(0x1F1C1410); // rgba(28,20,16,0.12)

  // ── Dark mode — Night Operations ────────────────────────────────────────
  static const dmBg            = Color(0xFF111008);
  static const dmSurface       = Color(0xFF1C1610);
  static const dmSurfaceRaised = Color(0xFF241D12);
  static const dmInk           = Color(0xFFD4C9A8);
  static const dmInkFaded      = Color(0xFF8A7A58);
  static const dmSignal        = Color(0xFFD4721F);
  static const dmSignalDim     = Color(0xFF7A4010);
  static const dmVerdigris     = Color(0xFF3A7A62);
  static const dmGridLine      = Color(0x12C8A850);
  static const dmBorder        = Color(0x1AD4C9A8);
  static const dmBorderActive  = Color(0x4DC8651A);

  // ── Semantic aliases (used by existing code) ─────────────────────────────
  // Keep these so Phase 4–8 code that references AppColors.feedbackCorrect etc.
  // still compiles without changes.
  static const feedbackCorrect        = verdigris;
  static const feedbackAmber          = tungsten;
  static const feedbackWrongWord      = rust;
  static const feedbackWrongConstraint = tungsten;
  static const feedbackIncorrect      = rust;
  static const primary                = signal;
  static const primaryDark            = signalDim;
  static const accent                 = tungsten;
  static const background             = parchment;
  static const surface                = aged;
  static const surfaceDark            = desk;
  static const tileDefault            = aged;
  static const tileSelected           = signal;
  static const tileLocked             = deepAged;
  static const tileConnected          = verdigris;
  static const textPrimary            = ink;
  static const textSecondary          = inkFaded;
  static const textOnDark             = parchment;
}
