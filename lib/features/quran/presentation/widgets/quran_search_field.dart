import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Search-by-name field at the top of the Quran tab (spec.md FR-005).
class QuranSearchField extends StatelessWidget {
  const QuranSearchField({
    super.key,
    required this.onChanged,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            drawSvgIcon(AppIcons.search,
                width: 18, height: 18, iconColor: textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText:
                      translator.word(TranslationKeys.quranSearchPlaceholder),
                  hintStyle: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 13,
                    color: textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
