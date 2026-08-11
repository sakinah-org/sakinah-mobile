import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/qibla_reading.dart';
import 'qibla_compass_dial.dart' show qiblaCompassPointLabel;

/// No-magnetometer fallback (spec.md FR-020) — a static degree value with
/// an explanatory message, no live dial.
class QiblaStaticBearingView extends StatelessWidget {
  const QiblaStaticBearingView({super.key, required this.reading});

  final QiblaStaticReading reading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surface,
            border: Border.all(color: border),
          ),
          child: drawSvgIcon(AppIcons.qibla,
              width: 36, height: 36, iconColor: brandPrimary),
        ),
        const SizedBox(height: 20),
        Text(
          '${reading.bearingDegrees.round()}°',
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${translator.word(TranslationKeys.qiblaDirectionLabel)} · '
          '${qiblaCompassPointLabel(reading.bearingDegrees)}',
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: brandPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            translator.word(TranslationKeys.qiblaNoSensorMessage),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
