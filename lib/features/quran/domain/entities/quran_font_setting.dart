import '../../../../utils/style/app_typography.dart';

/// The user's Quran text rendering preference (spec.md Key Entities) — a
/// font family (one of 3 bundled families) and a font size, stored locally
/// always and, when authenticated, additionally against the user's account.
class QuranFontSetting {
  final String fontFamily;
  final double fontSize;

  const QuranFontSetting({required this.fontFamily, required this.fontSize});

  /// The 3 selectable Quran reading fonts (spec.md FR-013), all bundled in
  /// `pubspec.yaml`: Lateef (default), Amiri, and QPCHafs — the standard
  /// King Fahd Complex "Hafs" Uthmani typeface. Originally planned as
  /// Lateef/Amiri/Nastaleeq per the design reference (research.md R9/R10),
  /// but Nastaleeq's bundled asset was later replaced with a set of
  /// purpose-built Quran typefaces (Amiri/Kitab/MeQuran/QPCHafs); QPCHafs
  /// is used here as the closer match to the design's "Uthmani" font slot
  /// — `AppTypography.ornamentalFontFamily` (Nastaleeq) remains reserved
  /// for its original wordmark/divider use elsewhere in the app, not Quran
  /// reading.
  static const List<String> availableFontFamilies = [
    AppTypography.quranFontFamily, // 'Lateef'
    'Amiri',
    'QPCHafs',
  ];

  /// No prior local or remote data (spec.md Edge Cases) — the existing
  /// default Quran font family, and the same size the `user_preferences`
  /// table itself defaults `quran_font_size` to, so a guest's local default
  /// and an authenticated user's server-side default agree.
  static const QuranFontSetting defaults = QuranFontSetting(
    fontFamily: AppTypography.quranFontFamily,
    fontSize: 20,
  );

  QuranFontSetting copyWith({String? fontFamily, double? fontSize}) =>
      QuranFontSetting(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );
}
