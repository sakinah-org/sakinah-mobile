import 'ayah.dart';
import 'surah.dart';

/// This page's ayahs belonging to one particular [surah], in order. A
/// [MushafPage] has one run per surah it contains — almost always exactly
/// one, but as many as three near the end of the Quran, where several
/// short surahs share a single page (e.g. page 604: Al-Ikhlas, Al-Falaq,
/// and An-Nas together — research.md R2 update).
class MushafPageSurahRun {
  final Surah surah;
  final List<Ayah> ayahs;

  const MushafPageSurahRun({required this.surah, required this.ayahs});
}

/// One of the 604 fixed pages of the standard Madani Mushaf layout
/// (spec.md Key Entities). [surahRuns] is never empty and lists every
/// surah this page contains, in reading order — one run for a
/// single-surah page (the vast majority), two or more for a page that
/// crosses one or more surah boundaries.
class MushafPage {
  final int pageNumber;
  final List<MushafPageSurahRun> surahRuns;

  const MushafPage({required this.pageNumber, required this.surahRuns});

  Surah get startSurah => surahRuns.first.surah;

  bool get isMixedPage => surahRuns.length > 1;
}
