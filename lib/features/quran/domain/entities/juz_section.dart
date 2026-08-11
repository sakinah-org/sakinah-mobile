import 'surah.dart';

/// One of the 30 traditional reading-division sections of the Quran
/// (spec.md Key Entities) — derived, presentation-facing, not persisted on
/// its own (data-model.md). Carries full [Surah] entities (not a reduced
/// shape) so the Juz tab shows identical per-Surah fields to the Surah tab.
class JuzSection {
  final int juzNumber;
  final List<Surah> surahs;

  const JuzSection({required this.juzNumber, required this.surahs});
}
