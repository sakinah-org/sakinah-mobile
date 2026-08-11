import '../../domain/entities/ayah_of_today.dart';

/// Maps the Al Quran Cloud `/ayah/{n}/editions/quran-uthmani,en.sahih`
/// response onto [AyahOfToday]. `data[0]` = Arabic (quran-uthmani),
/// `data[1]` = translation (en.sahih) — order follows the edition order in
/// the URL, per contracts/ayah_of_today_api.md.
class AyahOfTodayModel {
  static AyahOfToday fromAlQuranCloudJson(
    Map<String, dynamic> json,
    int globalAyahNumber,
    DateTime selectedForDate,
  ) {
    final data = json['data'] as List;
    final arabic = data[0] as Map<String, dynamic>;
    final translationEntry = data[1] as Map<String, dynamic>;
    final surah = arabic['surah'] as Map<String, dynamic>;

    return AyahOfToday(
      arabicText: arabic['text'] as String,
      translation: translationEntry['text'] as String,
      surahNumber: surah['number'] as int,
      surahName: surah['name'] as String,
      ayahNumberInSurah: arabic['numberInSurah'] as int,
      globalAyahNumber: globalAyahNumber,
      selectedForDate: selectedForDate,
    );
  }
}

/// Persisted envelope (data-model.md `CachedAyah`) — the single-slot "most
/// recently fetched" fallback for FR-013.
class CachedAyah {
  final AyahOfToday ayah;

  const CachedAyah({required this.ayah});

  Map<String, dynamic> toJson() => {
        'arabicText': ayah.arabicText,
        'translation': ayah.translation,
        'surahNumber': ayah.surahNumber,
        'surahName': ayah.surahName,
        'ayahNumberInSurah': ayah.ayahNumberInSurah,
        'globalAyahNumber': ayah.globalAyahNumber,
        'selectedForDate': ayah.selectedForDate.toIso8601String(),
      };

  static CachedAyah fromJson(Map json) {
    return CachedAyah(
      ayah: AyahOfToday(
        arabicText: json['arabicText'] as String,
        translation: json['translation'] as String,
        surahNumber: json['surahNumber'] as int,
        surahName: json['surahName'] as String,
        ayahNumberInSurah: json['ayahNumberInSurah'] as int,
        globalAyahNumber: json['globalAyahNumber'] as int,
        selectedForDate: DateTime.parse(json['selectedForDate'] as String),
      ),
    );
  }
}
