import '../../domain/entities/surah.dart';

/// Maps a single Al Quran Cloud `/surah` list entry — or, since the bundled
/// local fallback (`assets/quran/quran_uthmani.json`) uses the identical
/// field names, a bundled surah entry too — onto [Surah]. Also the Hive
/// envelope for the permanent local list cache (research.md R2).
class SurahModel {
  static Surah fromJson(Map<String, dynamic> json) => Surah(
        number: json['number'] as int,
        arabicName: json['name'] as String,
        transliteration: json['englishName'] as String,
        meaning: json['englishNameTranslation'] as String,
        revelationType:
            (json['revelationType'] as String).toLowerCase() == 'meccan'
                ? RevelationType.meccan
                : RevelationType.medinan,
        ayahCount: json['numberOfAyahs'] as int,
      );

  static List<Surah> listFromAlQuranCloudJson(Map<String, dynamic> json) {
    final data = json['data'] as List;
    return data
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<Surah> listFromBundledJson(Map<String, dynamic> json) {
    final surahs = json['surahs'] as List;
    return surahs
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Map<String, dynamic> toHiveJson(Surah surah) => {
        'number': surah.number,
        'name': surah.arabicName,
        'englishName': surah.transliteration,
        'englishNameTranslation': surah.meaning,
        'revelationType': surah.revelationType == RevelationType.meccan
            ? 'Meccan'
            : 'Medinan',
        'numberOfAyahs': surah.ayahCount,
      };

  static List<Map<String, dynamic>> listToHiveJson(List<Surah> surahs) =>
      surahs.map(toHiveJson).toList();

  static List<Surah> listFromHiveJson(List raw) =>
      raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
}
