import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// FR-018's explicit unable-to-load state — shared by the Quran tab and the
/// Surah Reading screen (contracts/quran_cubit_contract.md,
/// contracts/surah_reading_cubit_contract.md) rather than a blank screen.
class QuranUnavailableView extends StatelessWidget {
  const QuranUnavailableView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            drawSvgIcon(
              AppIcons.quran,
              width: 32,
              height: 32,
              iconColor: brandPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              translator.word(TranslationKeys.quranUnavailableMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                translator.word(TranslationKeys.homeRetryCta),
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
