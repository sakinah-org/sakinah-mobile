import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// FR-008 — shown at the top of the Prayers screen whenever all five
/// prayers' notification toggles are off (User Story 3). Purely reactive to
/// [PrayerNotificationSettingsLoadedState.allRemindersOff] — no state of
/// its own.
class PrayerRemindersOffBanner extends StatelessWidget {
  const PrayerRemindersOffBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          drawSvgIcon(AppIcons.notifications,
              width: 18, height: 18, iconColor: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              translator.word(TranslationKeys.prayersAllOffBannerMessage),
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
