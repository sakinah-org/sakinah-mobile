/// Single-member sealed state (data-model.md) — always resolves to a value
/// (falls back to `QuranFontSetting.defaults`), no loading/unavailable
/// state, since this never depends on network
/// (contracts/quran_font_settings_contract.md).
sealed class QuranFontSettingsState {
  const QuranFontSettingsState();
}

class QuranFontSettingsLoadedState extends QuranFontSettingsState {
  final String fontFamily;
  final double fontSize;

  const QuranFontSettingsLoadedState({
    required this.fontFamily,
    required this.fontSize,
  });

  QuranFontSettingsLoadedState copyWith({
    String? fontFamily,
    double? fontSize,
  }) =>
      QuranFontSettingsLoadedState(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
      );
}
