import 'package:flutter/material.dart';

/// Sakinah design system colors.
/// Base palette + co-equal light/dark semantic tokens.
abstract class AppColors {
  // ============================================================================
  // BASE PALETTE
  // ============================================================================

  static const Color teal900 = Color(0xFF065446);
  static const Color teal700 = Color(0xFF006754);
  static const Color teal600 = Color(0xFF158467);
  static const Color teal500 = Color(0xFF6B9B88);
  static const Color teal400 = Color(0xFF5BB895);
  static const Color teal300 = Color(0xFF87D1A4);

  static const Color neutral900 = Color(0xFF180E25);
  static const Color neutral600 = Color(0xFF827D89);
  static const Color neutral300 = Color(0xFFC8C5CB);
  static const Color neutral100 = Color(0xFFEFEEF0);
  static const Color neutral0 = Color(0xFFFFFFFF);

  static const Color red500 = Color(0xFFE74C3C);
  static const Color orange500 = Color(0xFFF39C12);
  static const Color blue500 = Color(0xFF3498DB);

  // ============================================================================
  // LIGHT THEME (default)
  // ============================================================================

  static const Color lightBg = neutral0;
  static const Color lightSurface = Color(0xFFFAF9FB);
  static const Color lightSurfaceRaised = neutral0;
  static const Color lightTextPrimary = neutral900;
  static const Color lightTextSecondary = neutral600;
  static const Color lightTextTertiary = neutral300;
  static const Color lightBorder = neutral100;
  static const Color lightBorderStrong = neutral300;
  static const Color lightBrandPrimary = teal600;
  static const Color lightBrandPrimaryDark = teal900;
  static const Color lightBrandPrimaryMedium = teal700;
  static const Color lightBrandPrimaryLight = teal300;
  static const Color lightOnBrand = Color(0xFFFFFFFF);

  // ============================================================================
  // DARK THEME
  // ============================================================================

  static const Color darkBg = Color(0xFF0F0A14);
  static const Color darkSurface = Color(0xFF1A1520);
  static const Color darkSurfaceRaised = Color(0xFF201A28);
  static const Color darkTextPrimary = Color(0xFFFAF9FB);
  static const Color darkTextSecondary = neutral300;
  static const Color darkTextTertiary = neutral600;
  static const Color darkBorder = Color(0xFF2A2530);
  static const Color darkBorderStrong = Color(0xFF3A3340);
  static const Color darkBrandPrimary = teal300;
  static const Color darkBrandPrimaryDark = teal600;
  static const Color darkBrandPrimaryMedium = teal600;
  static const Color darkBrandPrimaryLight = teal300;
  static const Color darkOnBrand = Color(0xFF0F0A14);

  // ============================================================================
  // SEMANTIC STATE (shared across themes)
  // ============================================================================

  static const Color success = teal600;
  static const Color error = red500;
  static const Color warning = orange500;
  static const Color info = blue500;
}
