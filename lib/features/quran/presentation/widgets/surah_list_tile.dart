import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/surah.dart';

/// One row in the Surah list (and, grouped under a [JuzSectionHeader], the
/// Juz list too) — number badge, Arabic name, transliteration · meaning,
/// and revelation type + ayah count (spec.md FR-002), matching the design's
/// diamond+square number badge layout (research.md R10).
class SurahListTile extends StatelessWidget {
  const SurahListTile({super.key, required this.surah, this.onTap});

  final Surah surah;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final brandPrimaryLight = isDark
        ? AppColors.darkBrandPrimaryLight
        : AppColors.lightBrandPrimaryLight;

    final revelationLabel = translator.word(
      surah.revelationType == RevelationType.meccan
          ? TranslationKeys.quranRevelationMeccan
          : TranslationKeys.quranRevelationMedinan,
    );
    final ayahCountLabel =
        '${surah.ayahCount} ${translator.word(TranslationKeys.quranAyahCountSuffix)}';

    log("Surah name : ${surah.arabicName}");
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: brandPrimaryLight.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Transform.rotate(
                    angle: 0.785398, // 45deg
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: brandPrimaryLight.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Text(
                    '${surah.number}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.arabicName,
                    style: TextStyle(
                      fontFamily: "Tajawal",
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.transliteration} · ${surah.meaning}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  revelationLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 10.5,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ayahCountLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 10.5,
                    color: textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
