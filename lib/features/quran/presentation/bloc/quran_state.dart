import '../../domain/entities/juz_section.dart';
import '../../domain/entities/surah.dart';

/// Which of the two view modes the Quran tab is showing (spec.md FR-003).
enum QuranTab { surah, juz }

sealed class QuranState {
  const QuranState();
}

class QuranInitialState extends QuranState {
  const QuranInitialState();
}

class QuranLoadingState extends QuranState {
  const QuranLoadingState();
}

/// [surahs] is always length 114, canonical order. [juzSections] stays
/// empty until the Juz tab has been opened at least once this session
/// (contracts/quran_cubit_contract.md). [searchQuery]/[searchResults] are
/// non-null only while a search is active (FR-008).
class QuranLoadedState extends QuranState {
  final List<Surah> surahs;
  final List<JuzSection> juzSections;
  final QuranTab activeTab;
  final String? searchQuery;
  final List<Surah>? searchResults;

  const QuranLoadedState({
    required this.surahs,
    required this.juzSections,
    required this.activeTab,
    this.searchQuery,
    this.searchResults,
  });

  QuranLoadedState copyWith({
    List<Surah>? surahs,
    List<JuzSection>? juzSections,
    QuranTab? activeTab,
    String? searchQuery,
    List<Surah>? searchResults,
    bool clearSearch = false,
  }) =>
      QuranLoadedState(
        surahs: surahs ?? this.surahs,
        juzSections: juzSections ?? this.juzSections,
        activeTab: activeTab ?? this.activeTab,
        searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
        searchResults:
            clearSearch ? null : (searchResults ?? this.searchResults),
      );
}

/// Neither the remote source nor the bundled local fallback could produce a
/// Surah list (FR-018).
class QuranUnavailableState extends QuranState {
  const QuranUnavailableState();
}
