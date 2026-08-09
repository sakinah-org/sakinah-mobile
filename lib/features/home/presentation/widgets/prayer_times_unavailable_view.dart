import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

enum PrayerTimesUnavailableVariant { locationRequired, unableToLoad }

/// FR-008 ("unable to load") / FR-009 ("set your location") states — never
/// a blank or fabricated prayer card.
class PrayerTimesUnavailableView extends StatelessWidget {
  const PrayerTimesUnavailableView({
    super.key,
    required this.variant,
    required this.onRetry,
  });

  final PrayerTimesUnavailableVariant variant;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    final isLocation =
        variant == PrayerTimesUnavailableVariant.locationRequired;
    final title = translator.word(isLocation
        ? TranslationKeys.homePrayerLocationRequiredTitle
        : TranslationKeys.homePrayerUnavailableTitle);
    final message = translator.word(isLocation
        ? TranslationKeys.homePrayerLocationRequiredMessage
        : TranslationKeys.homePrayerUnavailableMessage);
    final ctaKey = isLocation
        ? TranslationKeys.homeEnableLocationCta
        : TranslationKeys.homeRetryCta;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          drawSvgIcon(
            isLocation ? AppIcons.location : AppIcons.clock,
            width: 26,
            height: 26,
            iconColor: brandPrimary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              translator.word(ctaKey),
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
    );
  }
}
