import '../../domain/entities/surah.dart';

/// Maps a single bundled `assets/quran/chapters/index.json` entry (the
/// English-locale `risan/quran-json` chapter list — plan.md/research.md R2)
/// onto [Surah]. Also the Hive envelope for the permanent local list cache
/// (specs/004-quran-screen research.md R2).
class SurahModel {
  static Surah fromJson(Map<String, dynamic> json) => Surah(
        number: json['id'] as int,
        arabicName: json['name'] as String,
        transliteration: json['transliteration'] as String,
        meaning: json['translation'] as String,
        revelationType: (json['type'] as String).toLowerCase() == 'meccan'
            ? RevelationType.meccan
            : RevelationType.medinan,
        ayahCount: json['total_verses'] as int,
      );

  /// Parses the top-level array in `assets/quran/chapters/index.json`.
  static List<Surah> listFromBundledJson(List json) {
    return json
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Uses the same field names [fromJson] expects, so [listFromHiveJson]
  /// can reuse it for the cache round-trip without a second parser.
  static Map<String, dynamic> toHiveJson(Surah surah) => {
        'id': surah.number,
        'name': surah.arabicName,
        'transliteration': surah.transliteration,
        'translation': surah.meaning,
        'type': surah.revelationType == RevelationType.meccan
            ? 'meccan'
            : 'medinan',
        'total_verses': surah.ayahCount,
      };

  static List<Map<String, dynamic>> listToHiveJson(List<Surah> surahs) =>
      surahs.map(toHiveJson).toList();

  static List<Surah> listFromHiveJson(List raw) =>
      raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
}
