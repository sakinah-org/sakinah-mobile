import 'package:flutter/material.dart';

import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/ayah.dart';

/// Continuous ayat rendering with numbered circular badges (spec.md FR-010),
/// RTL, justified, generous line height. Base style is
/// [AppTypography.quranLight]/[quranDark]; [fontFamily]/[fontSize] override
/// it once `QuranFontSettingsCubit` is wired in (US5).
class AyahTextView extends StatelessWidget {
  const AyahTextView({
    super.key,
    required this.ayahs,
    this.fontFamily,
    this.fontSize,
  });

  final List<Ayah> ayahs;
  final String? fontFamily;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTypography.quranDark : AppTypography.quranLight;
    final textStyle = base.copyWith(fontFamily: fontFamily, fontSize: fontSize);
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final brandPrimaryLight = isDark
        ? AppColors.darkBrandPrimaryLight
        : AppColors.lightBrandPrimaryLight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: [
            for (final ayah in ayahs) ...[
              TextSpan(text: ayah.text, style: textStyle),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandPrimaryLight, width: 1.5),
                  ),
                  child: Text(
                    '${ayah.numberInSurah}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: brandPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
