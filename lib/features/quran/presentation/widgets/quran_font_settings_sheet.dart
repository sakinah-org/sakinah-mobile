import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/quran_font_setting.dart';
import '../bloc/quran_font_settings_cubit.dart';
import '../bloc/quran_font_settings_state.dart';
import 'quran_font_family_preview_card.dart';

const double _minFontSize = 16;
const double _maxFontSize = 36;

/// Font-settings bottom sheet (spec.md FR-012/013/014) — a size stepper +
/// slider, then the 3 selectable font families, each with a live preview
/// (research.md R10). Opened via [show].
class QuranFontSettingsSheet extends StatelessWidget {
  const QuranFontSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: QuranFontSettingsCubit.instance,
        child: const QuranFontSettingsSheet(),
      ),
    );
  }

  /// Lateef is labeled distinctly (Naskh, marked as the default); Amiri and
  /// QPCHafs are both genuinely Uthmani-style scripts, so they share that
  /// label (research.md R9 — QPCHafs replaces the design's original
  /// Nastaleeq slot after that font's bundled asset was swapped out).
  String _labelFor(String fontFamily) {
    final style = switch (fontFamily) {
      AppTypography.quranFontFamily =>
        '${translator.word(TranslationKeys.quranFontStyleNaskh)}'
            '${translator.word(TranslationKeys.quranFontDefaultSuffix)}',
      _ => translator.word(TranslationKeys.quranFontStyleUthmani),
    };
    return '$fontFamily · $style';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceRaised =
        isDark ? AppColors.darkSurfaceRaised : AppColors.lightSurfaceRaised;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return BlocBuilder<QuranFontSettingsCubit, QuranFontSettingsState>(
      builder: (context, state) {
        final loaded = state as QuranFontSettingsLoadedState;
        final cubit = context.read<QuranFontSettingsCubit>();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              decoration: BoxDecoration(
                color: surfaceRaised,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                        translator.word(TranslationKeys.quranFontSettingsTitle),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        translator.word(TranslationKeys.quranFontSizeLabel),
                        style: TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        '${loaded.fontSize.round()} pt',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _StepButton(
                        label: 'A',
                        fontSize: 13,
                        onTap: () => cubit.setFontSize(
                          (loaded.fontSize - 1)
                              .clamp(_minFontSize, _maxFontSize),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value:
                              loaded.fontSize.clamp(_minFontSize, _maxFontSize),
                          min: _minFontSize,
                          max: _maxFontSize,
                          activeColor: brandPrimary,
                          onChanged: (value) => cubit.setFontSize(value),
                        ),
                      ),
                      _StepButton(
                        label: 'A',
                        fontSize: 20,
                        onTap: () => cubit.setFontSize(
                          (loaded.fontSize + 1)
                              .clamp(_minFontSize, _maxFontSize),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      translator.word(TranslationKeys.quranFontTypeLabel),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFontFamily,
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  for (final family
                      in QuranFontSetting.availableFontFamilies) ...[
                    QuranFontFamilyPreviewCard(
                      fontFamily: family,
                      label: _labelFor(family),
                      selected: loaded.fontFamily == family,
                      onTap: () => cubit.setFontFamily(family),
                    ),
                    if (family != QuranFontSetting.availableFontFamilies.last)
                      const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
    );
  }
}
