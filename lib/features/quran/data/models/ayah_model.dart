import '../../domain/entities/ayah.dart';

/// Maps a bundled `assets/quran/chapters/{n}.json`'s `verses[]` entries
/// (`risan/quran-json` per-chapter shape — plan.md/research.md R2) onto
/// [Ayah]. Also the Hive envelope for the permanent per-Surah local cache
/// (specs/004-quran-screen research.md R2). Verses now also carry a `page`
/// field (specs/009-quran-paged-reading) — parsed as nullable to stay
/// tolerant of any shape drift, though the bundled assets always include it.
class AyahModel {
  static Ayah fromJson(Map<String, dynamic> json) => Ayah(
        numberInSurah: json['id'] as int,
        text: json['text'] as String,
        pageNumber: json['page'] as int?,
      );

  /// Parses one bundled Surah file's `verses[]` array.
  static List<Ayah> listFromBundledJson(Map<String, dynamic> surahJson) {
    final verses = surahJson['verses'] as List;
    return verses
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Uses the same field names [fromJson] expects, so [listFromHiveJson]
  /// can reuse it for the cache round-trip without a second parser.
  static Map<String, dynamic> toHiveJson(Ayah ayah) => {
        'id': ayah.numberInSurah,
        'text': ayah.text,
        'page': ayah.pageNumber,
      };

  static List<Map<String, dynamic>> listToHiveJson(List<Ayah> ayahs) =>
      ayahs.map(toHiveJson).toList();

  static List<Ayah> listFromHiveJson(List raw) =>
      raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
}
