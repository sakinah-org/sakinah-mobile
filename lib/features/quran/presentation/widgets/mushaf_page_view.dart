import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/mushaf_page.dart';
import 'ayah_text_view.dart';
import 'surah_transition_divider.dart';

/// Renders one [MushafPage]'s content: each surah run in order (with a
/// [SurahTransitionDivider] before any run that starts at that surah's
/// ayah 1 — its own opening page or a mid-page transition,
/// specs/009-quran-paged-reading research.md R2), plus the page-number
/// badge. [fontFamily]/[fontSize] pass straight through to [AyahTextView].
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    super.key,
    required this.page,
    this.fontFamily,
    this.fontSize,
  });

  final MushafPage page;
  final String? fontFamily;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final run in page.surahRuns) ...[
                  if (run.ayahs.first.numberInSurah == 1)
                    SurahTransitionDivider(surah: run.surah),
                  AyahTextView(
                    ayahs: run.ayahs,
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translator.word(TranslationKeys.quranPageBadgeLabel),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${page.pageNumber}',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: brandPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
