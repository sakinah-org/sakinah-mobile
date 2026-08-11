import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../bloc/quran_state.dart';

/// Surah/Juz segmented control (spec.md FR-003). Inert while [enabled] is
/// false — the search results view disables it (FR-008).
class QuranTabSwitcher extends StatelessWidget {
  const QuranTabSwitcher({
    super.key,
    required this.activeTab,
    required this.onChanged,
    this.enabled = true,
  });

  final QuranTab activeTab;
  final ValueChanged<QuranTab> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Widget segment(QuranTab tab, String label) {
      final selected = tab == activeTab;
      return Expanded(
        child: GestureDetector(
          onTap: enabled ? () => onChanged(tab) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: double.infinity,
            decoration: BoxDecoration(
              color: selected ? brandPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? onBrand : textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            segment(QuranTab.surah,
                translator.word(TranslationKeys.quranSurahTabLabel)),
            segment(QuranTab.juz,
                translator.word(TranslationKeys.quranJuzTabLabel)),
          ],
        ),
      ),
    );
  }
}
