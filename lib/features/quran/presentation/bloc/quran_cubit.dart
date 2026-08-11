import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/quran_repository.dart';
import 'quran_state.dart';

/// Feature-scoped (not a singleton) — provided via `BlocProvider` at
/// `QuranPage` only. Owns the Surah list, the active tab, and search — one
/// Cubit for all of it, per contracts/quran_cubit_contract.md.
class QuranCubit extends Cubit<QuranState> {
  QuranCubit({required QuranRepository repository})
      : _repository = repository,
        super(const QuranInitialState());

  final QuranRepository _repository;

  Future<void> loadSurahs() async {
    emit(const QuranLoadingState());
    try {
      final surahs = await _repository.getSurahList();
      emit(QuranLoadedState(
        surahs: surahs,
        juzSections: const [],
        activeTab: QuranTab.surah,
      ));
    } catch (_) {
      emit(const QuranUnavailableState());
    }
  }

  /// Fetches (and permanently caches, via the repository) the Juz grouping
  /// only the first time the Juz tab is opened this session — every
  /// subsequent switch is instant, reusing the already-loaded
  /// [QuranLoadedState.juzSections] (contracts/quran_cubit_contract.md).
  Future<void> switchTab(QuranTab tab) async {
    final current = state;
    if (current is! QuranLoadedState) return;
    if (current.searchQuery != null) return; // FR-008: inert while searching

    if (tab == QuranTab.juz && current.juzSections.isEmpty) {
      try {
        final juzSections = await _repository.getJuzSections();
        emit(current.copyWith(juzSections: juzSections, activeTab: tab));
      } catch (_) {
        // Juz data genuinely unavailable — stay on the Surah tab rather
        // than switching to an empty Juz view.
      }
      return;
    }

    emit(current.copyWith(activeTab: tab));
  }

  /// In-memory only, over the already-loaded Surah list (research.md R7) —
  /// never touches the network (FR-007). Matches the Arabic name or
  /// transliteration, case-insensitively, as a substring; the English
  /// meaning is deliberately NOT searched (spec.md Clarifications).
  void search(String query) {
    final current = state;
    if (current is! QuranLoadedState) return;

    final normalizedQuery = _normalizeForSearch(query);
    final results = current.surahs
        .where((s) =>
            _normalizeForSearch(s.arabicName).contains(normalizedQuery) ||
            _normalizeForSearch(s.transliteration).contains(normalizedQuery))
        .toList();

    emit(current.copyWith(searchQuery: query, searchResults: results));
  }

  void clearSearch() {
    final current = state;
    if (current is! QuranLoadedState) return;
    emit(current.copyWith(clearSearch: true));
  }

  /// Lowercases and, for Arabic text, strips combining diacritics (tashkeel:
  /// U+064B-U+065F, U+0670, U+06D6-U+06ED) and folds alef variants (madda,
  /// hamza-above/below, wasla) to a plain alef. The official Surah names
  /// come fully vocalized (e.g. Al-Faatiha's Arabic name renders with a
  /// dozen combining marks), but users typically type plain, undiacritized
  /// Arabic, which otherwise never matches as a substring.
  static final RegExp _arabicDiacriticsPattern = RegExp(
    '[ً-ٰٟۖ-ۭ]',
  );
  static final RegExp _arabicAlefVariantsPattern = RegExp(
    '[آأإٱ]',
  );

  String _normalizeForSearch(String value) => value
      .toLowerCase()
      .replaceAll(_arabicDiacriticsPattern, '')
      .replaceAll(_arabicAlefVariantsPattern, 'ا');
}
