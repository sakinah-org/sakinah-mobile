import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// The Surah Reading screen's bottom actions bar (spec.md Assumptions) —
/// exactly 3 buttons (listen, tafseer, share), each a no-op this phase; no
/// bookmark button, per the feature's explicit UI instruction (research.md
/// R8) — the design's own bottom bar includes a 4th bookmark button that is
/// deliberately not reproduced here.
class QuranReadingActionsBar extends StatelessWidget {
  const QuranReadingActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ActionButton(
              icon: AppIcons.listen,
              label: translator.word(TranslationKeys.quranListenActionLabel),
              color: textSecondary,
              // No-op this phase (spec.md Assumptions).
              onTap: () {},
            ),
            _ActionButton(
              icon: AppIcons.tafseer,
              label: translator.word(TranslationKeys.quranTafseerActionLabel),
              color: textSecondary,
              onTap: () {},
            ),
            _ActionButton(
              icon: AppIcons.share,
              label: translator.word(TranslationKeys.homeAyahShareCta),
              color: textSecondary,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            drawSvgIcon(icon, width: 20, height: 20, iconColor: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
