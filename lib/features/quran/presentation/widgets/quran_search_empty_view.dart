import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Explicit no-results state while a search query matches nothing
/// (spec.md FR-008 / Edge Cases), instead of an empty blank list.
class QuranSearchEmptyView extends StatelessWidget {
  const QuranSearchEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            drawSvgIcon(AppIcons.search,
                width: 28, height: 28, iconColor: textTertiary),
            const SizedBox(height: 10),
            Text(
              translator.word(TranslationKeys.quranSearchNoResultsMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
