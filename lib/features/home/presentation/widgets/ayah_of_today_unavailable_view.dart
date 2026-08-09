import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// FR-014: no ayah fresh or cached at all — explicit message + manual retry.
class AyahOfTodayUnavailableView extends StatelessWidget {
  const AyahOfTodayUnavailableView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final brandPrimaryLight = isDark
        ? AppColors.darkBrandPrimaryLight
        : AppColors.lightBrandPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Opacity(
                opacity: 0.5,
                child: drawSvgIcon(AppIcons.quote,
                    width: 26, height: 26, iconColor: brandPrimaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                translator.word(TranslationKeys.homeAyahUnavailableMessage),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  height: 1.55,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
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
      ],
    );
  }
}
