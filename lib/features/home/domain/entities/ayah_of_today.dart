/// A single Quranic verse selected to represent "today" — see
/// specs/002-home-page/data-model.md.
class AyahOfToday {
  final String arabicText;
  final String translation;
  final int surahNumber;
  final String surahName;
  final int ayahNumberInSurah;
  final int globalAyahNumber;

  /// The calendar date (device-local) this ayah was chosen to represent
  /// "today" for — the cache/staleness key (FR-011/FR-012).
  final DateTime selectedForDate;

  const AyahOfToday({
    required this.arabicText,
    required this.translation,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumberInSurah,
    required this.globalAyahNumber,
    required this.selectedForDate,
  });

  bool isFromToday(DateTime today) =>
      selectedForDate.year == today.year &&
      selectedForDate.month == today.month &&
      selectedForDate.day == today.day;
}
