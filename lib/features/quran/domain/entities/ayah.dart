/// A single verse within a Surah (spec.md Key Entities) — its number within
/// that Surah and its Arabic text, rendered on the Surah Reading screen.
class Ayah {
  final int numberInSurah;
  final String text;

  const Ayah({required this.numberInSurah, required this.text});
}
