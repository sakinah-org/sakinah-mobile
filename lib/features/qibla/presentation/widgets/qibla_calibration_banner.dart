import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Low-accuracy calibration prompt (spec.md FR-019 — figure-eight motion
/// guidance) — not covered by a dedicated screenshot in the imported
/// design mock, so this follows the app's existing warning-banner card
/// language (rounded, tinted, icon + short copy) for visual consistency.
class QiblaCalibrationBanner extends StatelessWidget {
  const QiblaCalibrationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    const warning = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, size: 18, color: warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translator.word(TranslationKeys.qiblaCalibrationTitle),
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  translator.word(TranslationKeys.qiblaCalibrationMessage),
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    color: warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
