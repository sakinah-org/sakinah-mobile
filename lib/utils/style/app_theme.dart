import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  fontFamily: AppTypography.uiFontFamily,
  primaryColor: AppColors.lightBrandPrimary,
  scaffoldBackgroundColor: AppColors.lightBg,
  canvasColor: AppColors.lightBg,
  shadowColor: Colors.black.withOpacity(0.1),

  colorScheme: const ColorScheme.light(
    primary: AppColors.lightBrandPrimary,
    onPrimary: AppColors.lightOnBrand,
    primaryContainer: AppColors.lightBrandPrimaryLight,
    onPrimaryContainer: AppColors.lightBrandPrimaryDark,
    secondary: AppColors.lightTextSecondary,
    onSecondary: AppColors.lightOnBrand,
    tertiary: AppColors.teal400,
    onTertiary: AppColors.lightOnBrand,
    error: AppColors.error,
    onError: AppColors.lightOnBrand,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightBorder,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightBorderStrong,
    outlineVariant: AppColors.lightBorder,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    foregroundColor: AppColors.lightTextPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.h2Light,
    surfaceTintColor: Colors.transparent,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightBrandPrimary,
      foregroundColor: AppColors.lightOnBrand,
      textStyle: AppTypography.buttonLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightBrandPrimary,
      side: const BorderSide(color: AppColors.lightBrandPrimary, width: 1.5),
      textStyle: AppTypography.buttonLight.copyWith(color: AppColors.lightBrandPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.lightBrandPrimary,
      textStyle: AppTypography.buttonLight.copyWith(color: AppColors.lightBrandPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),

  textTheme: AppTypography.lightTextTheme,

  cardTheme: CardThemeData(
    color: AppColors.lightSurfaceRaised,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.lightBorder),
    ),
    margin: const EdgeInsets.all(0),
    shadowColor: Colors.black.withOpacity(0.08),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.lightSurfaceRaised,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: AppTypography.h2Light,
    contentTextStyle: AppTypography.body1Light,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.lightBrandPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: AppTypography.body2Light,
    hintStyle: AppTypography.body2Light.copyWith(color: AppColors.lightTextTertiary),
    prefixIconColor: AppColors.lightTextSecondary,
    suffixIconColor: AppColors.lightTextSecondary,
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 1,
    space: 16,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurface,
    deleteIconColor: AppColors.lightTextSecondary,
    disabledColor: AppColors.lightBorder,
    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    selectedColor: AppColors.lightBrandPrimary,
    labelStyle: AppTypography.body2Light,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    side: const BorderSide(color: AppColors.lightBorder),
  ),

  iconTheme: const IconThemeData(
    color: AppColors.lightTextPrimary,
    size: 24,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightBrandPrimary,
    foregroundColor: AppColors.lightOnBrand,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.neutral900,
    contentTextStyle: AppTypography.body1Light.copyWith(color: AppColors.lightBg),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),

  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.lightSurfaceRaised,
    scrimColor: Colors.black.withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
  ),

  tabBarTheme: TabBarThemeData(
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.lightBrandPrimary, width: 3),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    labelColor: AppColors.lightBrandPrimary,
    unselectedLabelColor: AppColors.lightTextSecondary,
    labelStyle: AppTypography.body1Light,
    unselectedLabelStyle: AppTypography.body1Light,
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  fontFamily: AppTypography.uiFontFamily,
  primaryColor: AppColors.darkBrandPrimary,
  scaffoldBackgroundColor: AppColors.darkBg,
  canvasColor: AppColors.darkBg,
  shadowColor: Colors.black.withOpacity(0.3),

  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkBrandPrimary,
    onPrimary: AppColors.darkOnBrand,
    primaryContainer: AppColors.darkBrandPrimaryMedium,
    onPrimaryContainer: AppColors.darkOnBrand,
    secondary: AppColors.darkTextSecondary,
    onSecondary: AppColors.darkOnBrand,
    tertiary: AppColors.teal400,
    onTertiary: AppColors.darkOnBrand,
    error: AppColors.error,
    onError: AppColors.darkOnBrand,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkBorder,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorderStrong,
    outlineVariant: AppColors.darkBorder,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.h2Dark,
    surfaceTintColor: Colors.transparent,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkBrandPrimary,
      foregroundColor: AppColors.darkOnBrand,
      textStyle: AppTypography.buttonDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkBrandPrimary,
      side: const BorderSide(color: AppColors.darkBrandPrimary, width: 1.5),
      textStyle: AppTypography.buttonDark.copyWith(color: AppColors.darkBrandPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.darkBrandPrimary,
      textStyle: AppTypography.buttonDark.copyWith(color: AppColors.darkBrandPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),

  textTheme: AppTypography.darkTextTheme,

  cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.darkBorder),
    ),
    margin: const EdgeInsets.all(0),
    shadowColor: Colors.black.withOpacity(0.3),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.darkSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: AppTypography.h2Dark,
    contentTextStyle: AppTypography.body1Dark,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkBrandPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: AppTypography.body2Dark,
    hintStyle: AppTypography.body2Dark.copyWith(color: AppColors.darkTextTertiary),
    prefixIconColor: AppColors.darkTextSecondary,
    suffixIconColor: AppColors.darkTextSecondary,
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
    space: 16,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkSurface,
    deleteIconColor: AppColors.darkTextSecondary,
    disabledColor: AppColors.darkBorder,
    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    selectedColor: AppColors.darkBrandPrimary,
    labelStyle: AppTypography.body2Dark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    side: const BorderSide(color: AppColors.darkBorder),
  ),

  iconTheme: const IconThemeData(
    color: AppColors.darkTextPrimary,
    size: 24,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkBrandPrimary,
    foregroundColor: AppColors.darkOnBrand,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.darkSurfaceRaised,
    contentTextStyle: AppTypography.body1Dark.copyWith(color: AppColors.darkTextPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),

  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.darkSurface,
    scrimColor: Colors.black.withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
  ),

  tabBarTheme: TabBarThemeData(
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.darkBrandPrimary, width: 3),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    labelColor: AppColors.darkBrandPrimary,
    unselectedLabelColor: AppColors.darkTextSecondary,
    labelStyle: AppTypography.body1Dark,
    unselectedLabelStyle: AppTypography.body1Dark,
  ),
);
