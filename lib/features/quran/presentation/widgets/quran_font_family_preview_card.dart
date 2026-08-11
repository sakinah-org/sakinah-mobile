import 'package:flutter/material.dart';

import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// One selectable font-family option in [QuranFontSettingsSheet] — renders
/// the Basmala live in that face so the choice is felt, not guessed
/// (research.md R10). Selected = colored border + filled checkmark;
/// unselected = plain border + empty circle.
class QuranFontFamilyPreviewCard extends StatelessWidget {
  const QuranFontFamilyPreviewCard({
    super.key,
    required this.fontFamily,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String fontFamily;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _basmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? brandPrimary.withValues(alpha: 0.06) : null,
          border: Border.all(
            color: selected ? brandPrimary : border,
            width: selected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      _basmala,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 20,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 10.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? brandPrimary : null,
                border:
                    selected ? null : Border.all(color: borderStrong, width: 2),
              ),
              child:
                  selected ? Icon(Icons.check, size: 13, color: onBrand) : null,
            ),
          ],
        ),
      ),
    );
  }
}
