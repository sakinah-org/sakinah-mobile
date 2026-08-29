/// A single verse within a Surah (spec.md Key Entities) — its number within
/// that Surah and its Arabic text, rendered on the Surah Reading screen.
class Ayah {
  final int numberInSurah;
  final String text;

  /// Which of the 604 Mushaf pages this ayah belongs to
  /// (specs/009-quran-paged-reading data-model.md). Nullable only to avoid
  /// the type lying about pre-migration cached data (research.md R5) — in
  /// normal operation, every [Ayah] the app produces has this populated.
  final int? pageNumber;

  const Ayah({
    required this.numberInSurah,
    required this.text,
    this.pageNumber,
  });
}
