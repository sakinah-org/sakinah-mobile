import 'package:flutter/material.dart';

import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Sakinah wordmark + notification bell, matching the Home screen mock's
/// top row. The bell is intentionally non-interactive — no notifications
/// feature exists yet to navigate to.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'سكينة',
            style: TextStyle(
              fontFamily: AppTypography.ornamentalFontFamily,
              fontSize: 30,
              height: 1,
              color: brandPrimary,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            child: Stack(
              alignment: Alignment.center,
              children: [
                drawSvgIcon(
                  AppIcons.notifications,
                  width: 20,
                  height: 20,
                  iconColor: textSecondary,
                ),
                Positioned(
                  top: 9,
                  right: 11,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
