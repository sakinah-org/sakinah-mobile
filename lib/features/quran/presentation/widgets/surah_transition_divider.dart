import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/surah.dart';

/// Marks the start of a new surah within a page's content — either a page
/// that is entirely that surah's own first page, or (specs/009-quran-paged-
/// reading research.md R2) a later run on a page that also contains the
/// end of the previous surah. Shown before any [Surah] run whose first ayah
/// is ayah 1. Surah name + the Basmala, except for At-Tawbah (9), which by
/// classical Mushaf convention opens with no Basmala.
class SurahTransitionDivider extends StatelessWidget {
  const SurahTransitionDivider({super.key, required this.surah});

  final Surah surah;

  static const _basmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final revelationLabel = translator.word(
      surah.revelationType == RevelationType.meccan
          ? TranslationKeys.quranRevelationMeccan
          : TranslationKeys.quranRevelationMedinan,
    );
    final ayahCountLabel =
        '${surah.ayahCount} ${translator.word(TranslationKeys.quranAyahCountSuffix)}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              surah.arabicName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: brandPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$revelationLabel · $ayahCountLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 10.5,
                color: textSecondary,
              ),
            ),
            if (surah.number != 9) ...[
              const SizedBox(height: 10),
              Text(
                _basmala,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.ornamentalFontFamily,
                  fontSize: 22,
                  color: brandPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
