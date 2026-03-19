// lib/core/theme/app_text_styles.dart
// Phase 9 — MERIDIAN design language for Intercept.
import 'package:flutter/material.dart';

class AppTextStyles {
  // Display — Oswald
  static const appName    = TextStyle(fontFamily: 'Oswald', fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 3.96);
  static const displayXL  = TextStyle(fontFamily: 'Oswald', fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: 11.2);
  static const displayLG  = TextStyle(fontFamily: 'Oswald', fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 2.4);
  static const displayMD  = TextStyle(fontFamily: 'Oswald', fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 1.8);
  static const displaySM  = TextStyle(fontFamily: 'Oswald', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 1.68);

  // Labels — Special Elite
  static const labelXL    = TextStyle(fontFamily: 'SpecialElite', fontSize: 13, letterSpacing: 0.26);
  static const labelLG    = TextStyle(fontFamily: 'SpecialElite', fontSize: 11, letterSpacing: 1.32);
  static const labelMD    = TextStyle(fontFamily: 'SpecialElite', fontSize: 10, letterSpacing: 1.4);
  static const labelSM    = TextStyle(fontFamily: 'SpecialElite', fontSize: 9,  letterSpacing: 1.62);
  static const labelXS    = TextStyle(fontFamily: 'SpecialElite', fontSize: 8,  letterSpacing: 1.12);

  // Mono — Courier Prime
  static const monoMD     = TextStyle(fontFamily: 'CourierPrime', fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.65);
  static const monoSM     = TextStyle(fontFamily: 'CourierPrime', fontSize: 10, letterSpacing: 0.8);
  static const monoXS     = TextStyle(fontFamily: 'CourierPrime', fontSize: 9,  letterSpacing: 0.9);

  // Game-specific
  static const tileLabel        = TextStyle(fontFamily: 'Oswald', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.0);
  static const constraintLabel  = TextStyle(fontFamily: 'SpecialElite', fontSize: 11, letterSpacing: 1.32);
}
