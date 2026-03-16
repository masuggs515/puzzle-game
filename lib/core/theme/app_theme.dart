// lib/core/theme/app_theme.dart
// Phase 9 — MERIDIAN design language
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.parchment,
    colorScheme: const ColorScheme.light(
      primary: AppColors.signal,
      onPrimary: AppColors.parchment,
      secondary: AppColors.verdigris,
      onSecondary: AppColors.parchment,
      error: AppColors.rust,
      surface: AppColors.aged,
      onSurface: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.desk,
      foregroundColor: AppColors.parchment,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.signal,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.button),
        ),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.signal,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.button),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkFaded,
        side: const BorderSide(color: Color(0x331C1410)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.button),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.modal),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.desk,
      contentTextStyle: TextStyle(color: AppColors.parchment, fontFamily: 'SpecialElite'),
    ),
  );
}
