import 'package:flutter/material.dart';

import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Single row in the Settings options list (design §08 row treatment):
/// tinted icon square, label, an optional trailing value, and a chevron.
/// Grouping (rounded container + dividers between rows) is composed by the
/// caller (`SettingsPage`), not this widget.
class SettingsOptionTile extends StatelessWidget {
  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingValue,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: drawSvgIcon(icon,
                  width: 18, height: 18, iconColor: brandPrimary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              Text(
                trailingValue!,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            RotatedBox(
              quarterTurns: isArabic ? 2 : 0,
              child: drawSvgIcon(AppIcons.chevronRight,
                  width: 18, height: 18, iconColor: textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
