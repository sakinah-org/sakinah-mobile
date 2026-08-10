import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/prayer_times/presentation/prayer_code_presentation.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// One row in the Prayers screen's list: name + time (FR-002), the fixed
/// "10 minutes before" caption, and an on/off toggle (FR-003). The toggle
/// is visually disabled (greyed, non-interactive) when notification
/// permission isn't granted (FR-014) — [onToggle] is null in that case.
class PrayerReminderTile extends StatelessWidget {
  const PrayerReminderTile({
    super.key,
    required this.code,
    required this.time,
    required this.isEnabled,
    required this.onToggle,
  });

  final String code;
  final DateTime time;
  final bool isEnabled;
  final ValueChanged<bool>? onToggle;

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
    final locale = Localizations.localeOf(context);
    final interactive = onToggle != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          drawSvgIcon(prayerCodeIcon(code),
              width: 24,
              height: 24,
              iconColor: interactive ? brandPrimary : textSecondary,),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerCodeLabel(code),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  translator.word(TranslationKeys.prayersReminderOffsetCaption),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat.jm(locale.languageCode).format(time),
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeTrackColor: brandPrimary,
          ),
        ],
      ),
    );
  }
}
