import '../../domain/entities/ayah.dart';

/// Maps Al Quran Cloud `/surah/{n}/quran-uthmani` `ayahs[]` entries — or the
/// identically-shaped bundled fallback entries — onto [Ayah]. Also the Hive
/// envelope for the permanent per-Surah local cache (research.md R2).
class AyahModel {
  static Ayah fromJson(Map<String, dynamic> json) => Ayah(
        numberInSurah: json['numberInSurah'] as int,
        text: json['text'] as String,
      );

  static List<Ayah> listFromAlQuranCloudJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List;
    return ayahs
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<Ayah> listFromBundledJson(Map<String, dynamic> surahJson) {
    final ayahs = surahJson['ayahs'] as List;
    return ayahs
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Map<String, dynamic> toHiveJson(Ayah ayah) => {
        'numberInSurah': ayah.numberInSurah,
        'text': ayah.text,
      };

  static List<Map<String, dynamic>> listToHiveJson(List<Ayah> ayahs) =>
      ayahs.map(toHiveJson).toList();

  static List<Ayah> listFromHiveJson(List raw) =>
      raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
}
