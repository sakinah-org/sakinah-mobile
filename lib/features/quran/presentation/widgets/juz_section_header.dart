import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Inline divider header for one Juz section on the Juz tab (spec.md FR-004)
/// — a numbered pill plus a "Juz N" label, matching the design's per-Juz
/// divider treatment (research.md R10).
class JuzSectionHeader extends StatelessWidget {
  const JuzSectionHeader({super.key, required this.juzNumber});

  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: brandPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$juzNumber',
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: onBrand,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '${translator.word(TranslationKeys.quranJuzSectionLabel)} $juzNumber',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: brandPrimary,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Divider(color: border, height: 1)),
        ],
      ),
    );
  }
}
