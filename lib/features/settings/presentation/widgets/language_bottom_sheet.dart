import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/bloc/settings_cubit.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Language bottom sheet (spec.md FR-008–FR-011, design §06) — opened from
/// the "Change Language" row in Settings. Only Arabic/English are offered,
/// per this feature's explicit UI instruction to ignore any other
/// languages the design system otherwise lists.
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  static const _languages = ['ar', 'en'];

  /// Each language's own name, in its own script — fixed regardless of the
  /// app's currently active locale (unlike everything else in this app,
  /// these are proper nouns, not translatable UI copy), so this deliberately
  /// bypasses `translator`/`TranslationKeys`.
  static String nativeName(String languageCode) =>
      languageCode == 'ar' ? 'العربية' : 'English';

  /// The other language's name for `languageCode` — e.g. "Arabic" under the
  /// Arabic row, "الإنجليزية" under the English row. Same reasoning as
  /// [nativeName]: always shown together, regardless of the active locale.
  static String glossName(String languageCode) =>
      languageCode == 'ar' ? 'Arabic' : 'الإنجليزية';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceRaised =
        isDark ? AppColors.darkSurfaceRaised : AppColors.lightSurfaceRaised;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;

    final activeCode = context.watch<SettingsCubit>().locale.languageCode;

    return SafeArea(
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
                  translator.word(TranslationKeys.languageSheetTitle),
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
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                translator.word(TranslationKeys.languageSheetFootnote),
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontSize: 12,
                  color: textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final code in _languages) ...[
              _LanguageRow(
                selected: code == activeCode,
                nativeName: nativeName(code),
                glossName: glossName(code),
                border: border,
                brandPrimary: brandPrimary,
                borderStrong: borderStrong,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onBrand: onBrand,
                onTap: () =>
                    context.read<SettingsCubit>().setLocale(Locale(code)),
              ),
              if (code != _languages.last) const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.selected,
    required this.nativeName,
    required this.glossName,
    required this.border,
    required this.brandPrimary,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.onBrand,
    required this.onTap,
  });

  final bool selected;
  final String nativeName;
  final String glossName;
  final Color border;
  final Color brandPrimary;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color onBrand;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await onTap();
        if (context.mounted) Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? brandPrimary.withValues(alpha: 0.06) : null,
          border: Border.all(
            color: selected ? brandPrimary : border,
            width: selected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    glossName,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandPrimary,
                ),
                child: Icon(Icons.check, size: 13, color: onBrand),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderStrong, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
