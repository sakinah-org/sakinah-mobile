import 'package:flutter/material.dart';

import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// A toggle row in the Settings options list (specs/008-dark-mode): same
/// icon-square + label layout as [SettingsOptionTile], but with a trailing
/// [Switch] instead of a chevron — for a binary on/off preference rather
/// than a navigation target. Mirrors the `Switch` usage already established
/// by `PrayerReminderTile` (research.md R2).
class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return Padding(
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: brandPrimary,
          ),
        ],
      ),
    );
  }
}
