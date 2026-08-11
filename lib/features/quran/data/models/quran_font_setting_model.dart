import '../../domain/entities/quran_font_setting.dart';

/// Hive scalar (de)serialization + `public.user_preferences` row mapping for
/// [QuranFontSetting] — data-model.md.
class QuranFontSettingModel {
  static Map<String, dynamic> toSupabaseRow(
    QuranFontSetting setting, {
    required String userId,
  }) {
    return {
      'user_id': userId,
      'quran_font_family': setting.fontFamily,
      'quran_font_size': setting.fontSize.round(),
    };
  }

  static QuranFontSetting? fromSupabaseRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final family = row['quran_font_family'] as String?;
    final size = row['quran_font_size'] as int?;
    if (family == null || size == null) return null;
    return QuranFontSetting(fontFamily: family, fontSize: size.toDouble());
  }
}
