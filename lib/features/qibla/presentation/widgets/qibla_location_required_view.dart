import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Location-unavailable fallback (spec.md FR-021) — explanation + a
/// grant/retry action, following the same card language as
/// `PrayerTimesUnavailableView` (lib/shared/prayer_times/presentation/).
class QiblaLocationRequiredView extends StatelessWidget {
  const QiblaLocationRequiredView({super.key, required this.onRetry});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            drawSvgIcon(AppIcons.location,
                width: 30, height: 30, iconColor: brandPrimary),
            const SizedBox(height: 12),
            Text(
              translator.word(TranslationKeys.qiblaLocationRequiredMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onRetry,
              child: Text(
                translator.word(TranslationKeys.homeEnableLocationCta),
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
