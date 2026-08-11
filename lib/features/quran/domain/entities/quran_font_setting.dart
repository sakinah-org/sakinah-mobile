/// The user's Quran text rendering preference (spec.md Key Entities) — a
/// font family (one of 4 bundled families) and a font size, stored locally
/// always and, when authenticated, additionally against the user's account.
class QuranFontSetting {
  final String fontFamily;
  final double fontSize;

  const QuranFontSetting({required this.fontFamily, required this.fontSize});

  /// The 4 selectable Quran reading fonts (specs/005-quran-fonts-local-
  /// source spec.md FR-001), all bundled in `pubspec.yaml`: Amiri, Kitab,
  /// MeQuran, and QPCHafs — the standard King Fahd Complex "Hafs" Uthmani
  /// typeface, also this set's default (research.md R6). Replaces the
  /// previous 3-family set (Lateef/Amiri/QPCHafs, specs/004-quran-screen
  /// research.md R9) — Lateef (a general-purpose Naskh font, not
  /// Quran-specific) is dropped; Kitab and MeQuran are added.
  static const List<String> availableFontFamilies = [
    'Amiri',
    'Kitab',
    'MeQuran',
    'QPCHafs',
  ];

  /// No prior local or remote data, or a previously saved family that's no
  /// longer offered — e.g. a pre-update user's 'Lateef' (spec.md Edge
  /// Cases/FR-006) — the standard Uthmani "Hafs" typeface, and the same
  /// size the `user_preferences` table itself defaults `quran_font_size`
  /// to, so a guest's local default and an authenticated user's
  /// server-side default agree.
  static const QuranFontSetting defaults = QuranFontSetting(
    fontFamily: 'QPCHafs',
    fontSize: 20,
  );

  QuranFontSetting copyWith({String? fontFamily, double? fontSize}) =>
      QuranFontSetting(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );
}
