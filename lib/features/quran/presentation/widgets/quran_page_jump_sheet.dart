import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../bloc/surah_reading_cubit.dart';

enum _JumpTab { page, juz }

/// The page/Juz jump bottom sheet (spec.md User Story 3, FR-010/FR-011) —
/// opened from `SurahReadingPage`'s app-bar page-jump button. [onJumpToPage]
/// is called with the resolved target page (1–[totalPages]); the caller
/// owns the actual `PageController.jumpToPage` call (research.md R7 — an
/// instant jump, no animation) and closing this sheet.
class QuranPageJumpSheet extends StatefulWidget {
  const QuranPageJumpSheet({
    super.key,
    required this.totalPages,
    required this.onJumpToPage,
  });

  final int totalPages;
  final ValueChanged<int> onJumpToPage;

  static Future<void> show(
    BuildContext context, {
    required int totalPages,
    required ValueChanged<int> onJumpToPage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<SurahReadingCubit>(),
        child: QuranPageJumpSheet(
          totalPages: totalPages,
          onJumpToPage: onJumpToPage,
        ),
      ),
    );
  }

  @override
  State<QuranPageJumpSheet> createState() => _QuranPageJumpSheetState();
}

class _QuranPageJumpSheetState extends State<QuranPageJumpSheet> {
  _JumpTab _activeTab = _JumpTab.page;
  final _pageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int? get _validPageEntry {
    final value = int.tryParse(_pageController.text);
    if (value == null || value < 1 || value > widget.totalPages) return null;
    return value;
  }

  void _submitPage() {
    final page = _validPageEntry;
    if (page == null) return;
    widget.onJumpToPage(page);
    Navigator.of(context).pop();
  }

  Future<void> _submitJuz(int juzNumber) async {
    final page =
        await context.read<SurahReadingCubit>().resolveJuzFirstPage(juzNumber);
    widget.onJumpToPage(page);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceRaised =
        isDark ? AppColors.darkSurfaceRaised : AppColors.lightSurfaceRaised;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          decoration: BoxDecoration(
            color: surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translator.word(TranslationKeys.quranJumpSheetTitle),
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: drawSvgIcon(AppIcons.close,
                        width: 16, height: 16, iconColor: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: translator
                            .word(TranslationKeys.quranJumpPageTabLabel),
                        selected: _activeTab == _JumpTab.page,
                        brandPrimary: brandPrimary,
                        onBrand: onBrand,
                        textSecondary: textSecondary,
                        onTap: () => setState(() => _activeTab = _JumpTab.page),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: translator
                            .word(TranslationKeys.quranJumpJuzTabLabel),
                        selected: _activeTab == _JumpTab.juz,
                        brandPrimary: brandPrimary,
                        onBrand: onBrand,
                        textSecondary: textSecondary,
                        onTap: () => setState(() => _activeTab = _JumpTab.juz),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_activeTab == _JumpTab.page)
                _PageNumberTab(
                  controller: _pageController,
                  isValid: _validPageEntry != null,
                  onSubmit: _submitPage,
                  totalPages: widget.totalPages,
                  border: border,
                  brandPrimary: brandPrimary,
                  onBrand: onBrand,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              else
                _JuzGridTab(
                  onSelect: _submitJuz,
                  border: border,
                  brandPrimary: brandPrimary,
                  textSecondary: textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.brandPrimary,
    required this.onBrand,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color brandPrimary;
  final Color onBrand;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? brandPrimary : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? onBrand : textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PageNumberTab extends StatelessWidget {
  const _PageNumberTab({
    required this.controller,
    required this.isValid,
    required this.onSubmit,
    required this.totalPages,
    required this.border,
    required this.brandPrimary,
    required this.onBrand,
    required this.textPrimary,
    required this.textSecondary,
  });

  final TextEditingController controller;
  final bool isValid;
  final VoidCallback onSubmit;
  final int totalPages;
  final Color border;
  final Color brandPrimary;
  final Color onBrand;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: brandPrimary, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setLocalState(() {}),
                      onSubmitted: (_) => onSubmit(),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFontFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isValid ? onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary,
                      foregroundColor: onBrand,
                      disabledBackgroundColor:
                          brandPrimary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      translator.word(TranslationKeys.quranJumpGoCta),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              translator.word(TranslationKeys.quranJumpPageRangeHint),
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 10.5,
                color: textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JuzGridTab extends StatelessWidget {
  const _JuzGridTab({
    required this.onSelect,
    required this.border,
    required this.brandPrimary,
    required this.textSecondary,
  });

  final ValueChanged<int> onSelect;
  final Color border;
  final Color brandPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translator.word(TranslationKeys.quranJumpJuzHint),
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.4,
          children: [
            for (var juz = 1; juz <= 30; juz++)
              InkWell(
                onTap: () => onSelect(juz),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$juz',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
