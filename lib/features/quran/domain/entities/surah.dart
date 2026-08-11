/// Whether a Surah was revealed in Mecca or Medina.
enum RevelationType { meccan, medinan }

/// One chapter of the Quran (spec.md Key Entities) — number, Arabic name,
/// transliteration, English meaning, revelation type, and ayah count.
class Surah {
  final int number;
  final String arabicName;
  final String transliteration;
  final String meaning;
  final RevelationType revelationType;
  final int ayahCount;

  const Surah({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.meaning,
    required this.revelationType,
    required this.ayahCount,
  });
}
