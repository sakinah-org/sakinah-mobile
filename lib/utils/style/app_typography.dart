import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sakinah typography scale.
/// Tajawal is the UI workhorse; Lateef is reserved for Quranic verse text;
/// KFGQPC Nastaleeq is an ornamental script for wordmark/divider moments only.
abstract class AppTypography {
  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  static const String uiFontFamily = 'Tajawal';
  static const String quranFontFamily = 'Lateef';
  static const String ornamentalFontFamily = 'Nastaleeq';

  // ============================================================================
  // APP NAME
  // ============================================================================

  static const TextStyle appNameRegular = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w400,
    fontFamily: ornamentalFontFamily,
    color: AppColors.lightBrandPrimary,
  );
  // ============================================================================
  // HEADINGS
  // ============================================================================

  static const TextStyle h1Light = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 20 / 20,
    letterSpacing: -0.4,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle h1Dark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 20 / 20,
    letterSpacing: -0.4,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle h2Light = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
    letterSpacing: -0.24,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle h2Dark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
    letterSpacing: -0.24,
    color: AppColors.darkTextPrimary,
  );

  // ============================================================================
  // BODY
  // ============================================================================

  static const TextStyle body1Light = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 24 / 14,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle body1Dark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 24 / 14,
    color: AppColors.darkTextPrimary,
  );

  static const TextStyle body2Light = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 12 / 12,
    color: AppColors.lightTextSecondary,
  );

  static const TextStyle body2Dark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 12 / 12,
    color: AppColors.darkTextSecondary,
  );

  static const TextStyle body3Light = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 12 / 10,
    color: AppColors.lightTextTertiary,
  );

  static const TextStyle body3Dark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 12 / 10,
    color: AppColors.darkTextTertiary,
  );

  // ============================================================================
  // BUTTON
  // ============================================================================

  static const TextStyle buttonLight = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 14 / 16,
    color: AppColors.lightOnBrand,
  );

  static const TextStyle buttonDark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 14 / 16,
    color: AppColors.darkOnBrand,
  );

  // ============================================================================
  // DISPLAY
  // ============================================================================

  static const TextStyle displayLight = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 38 / 32,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle displayDark = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 38 / 32,
    color: AppColors.darkTextPrimary,
  );

  // ============================================================================
  // QURAN (Lateef)
  // ============================================================================

  static const TextStyle quranLight = TextStyle(
    fontFamily: quranFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    height: 52 / 26,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle quranDark = TextStyle(
    fontFamily: quranFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    height: 52 / 26,
    color: AppColors.darkTextPrimary,
  );

  // ============================================================================
  // TEXT THEME BUILDERS
  // ============================================================================

  static TextTheme get lightTextTheme => const TextTheme(
        displayLarge: h1Light,
        displayMedium: h2Light,
        displaySmall: h2Light,
        headlineMedium: h2Light,
        headlineSmall: body1Light,
        titleLarge: body1Light,
        titleMedium: body2Light,
        titleSmall: body3Light,
        bodyLarge: body1Light,
        bodyMedium: body2Light,
        bodySmall: body3Light,
        labelLarge: buttonLight,
        labelMedium: body2Light,
        labelSmall: body3Light,
      );

  static TextTheme get darkTextTheme => const TextTheme(
        displayLarge: h1Dark,
        displayMedium: h2Dark,
        displaySmall: h2Dark,
        headlineMedium: h2Dark,
        headlineSmall: body1Dark,
        titleLarge: body1Dark,
        titleMedium: body2Dark,
        titleSmall: body3Dark,
        bodyLarge: body1Dark,
        bodyMedium: body2Dark,
        bodySmall: body3Dark,
        labelLarge: buttonDark,
        labelMedium: body2Dark,
        labelSmall: body3Dark,
      );
}
