sealed class SurahReadingState {
  const SurahReadingState();
}

class SurahReadingInitialState extends SurahReadingState {
  const SurahReadingInitialState();
}

class SurahReadingLoadingState extends SurahReadingState {
  const SurahReadingLoadingState();
}

/// specs/009-quran-paged-reading — the loaded state no longer holds ayah
/// content directly (that was the pre-paging `{surah, ayahs}` shape); each
/// `PageView` item fetches its own `MushafPage` on demand
/// (contracts/surah_reading_cubit_contract.md). This state only carries
/// what's needed to construct the `PageView`/`PageController` once.
class SurahReadingLoadedState extends SurahReadingState {
  final int startingPageNumber;
  final int totalPages;

  const SurahReadingLoadedState({
    required this.startingPageNumber,
    required this.totalPages,
  });
}

/// Neither the remote source nor the bundled local fallback could produce
/// this Surah's text (FR-018).
class SurahReadingUnavailableState extends SurahReadingState {
  const SurahReadingUnavailableState();
}
