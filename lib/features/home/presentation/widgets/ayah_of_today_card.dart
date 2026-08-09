import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/ayah_of_today.dart';

/// "Ayah of Today" section: header + Share action, then the verse card.
/// Height is intentionally unbounded (FR-015/SC-006) — the page scrolls,
/// the card never clips the verse.
class AyahOfTodayCard extends StatelessWidget {
  const AyahOfTodayCard({
    super.key,
    required this.ayah,
    required this.isFromToday,
  });

  final AyahOfToday ayah;
  final bool isFromToday;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final brandPrimaryDark = isDark
        ? AppColors.darkBrandPrimaryDark
        : AppColors.lightBrandPrimaryDark;
    final brandPrimaryLight = isDark
        ? AppColors.darkBrandPrimaryLight
        : AppColors.lightBrandPrimaryLight;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final ayahNumberLabel = NumberFormat.decimalPattern(locale.languageCode)
        .format(ayah.ayahNumberInSurah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translator.word(TranslationKeys.homeAyahSectionTitle),
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => Share.share(
                '${ayah.arabicText}\n\n"${ayah.translation}"\n— ${ayah.surahName} ${ayah.ayahNumberInSurah}',
              ),
              icon: drawSvgIcon(AppIcons.share,
                  width: 15, height: 15, iconColor: brandPrimary),
              label: Text(
                translator.word(TranslationKeys.homeAyahShareCta),
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brandPrimary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
              Text(
                ayah.arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppTypography.quranFontFamily,
                  fontSize: 27,
                  height: 52 / 27,
                  color: brandPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${ayah.translation}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  height: 1.55,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ayah.surahName} · $ayahNumberLabel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 11,
                  color: textTertiary,
                ),
              ),
              if (!isFromToday) ...[
                const SizedBox(height: 6),
                Text(
                  translator.word(TranslationKeys.homeAyahCachedLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
