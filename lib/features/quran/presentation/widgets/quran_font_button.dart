import 'package:flutter/material.dart';

import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// The font-settings app-bar trigger (spec.md FR-012) — a plain "Aa"
/// text-style button (two stacked letter sizes), matching the design
/// exactly rather than a new SVG icon (research.md R10/R13).
class QuranFontButton extends StatelessWidget {
  const QuranFontButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontWeight: FontWeight.w800,
              color: brandPrimary,
            ),
            children: const [
              TextSpan(text: 'A', style: TextStyle(fontSize: 15)),
              TextSpan(text: 'a', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
