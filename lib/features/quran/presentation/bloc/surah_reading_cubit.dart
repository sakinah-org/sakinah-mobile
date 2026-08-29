import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/quran_repository.dart';
import 'surah_reading_state.dart';

/// Total fixed Mushaf page count (spec.md Assumptions) — the `PageView`'s
/// `itemCount` single source of truth (data-model.md).
const int kQuranTotalPages = 604;

/// Feature-scoped (not a singleton) — provided via `BlocProvider` at
/// `SurahReadingPage` only, one instance per screen visit. See
/// contracts/surah_reading_cubit_contract.md.
class SurahReadingCubit extends Cubit<SurahReadingState> {
  SurahReadingCubit({required QuranRepository repository})
      : _repository = repository,
        super(const SurahReadingInitialState());

  final QuranRepository _repository;

  /// Exposed so `PageView` items and the jump sheet can call
  /// `getPage`/`firstPageOfJuz` etc. directly, reusing this same
  /// (Hive-cache-backed) instance rather than constructing a new one.
  QuranRepository get repository => _repository;

  /// Entry point when arriving from the Surah list (spec.md FR-005).
  Future<void> initialize(int surahNumber) async {
    emit(const SurahReadingLoadingState());
    try {
      final pageNumber = await _repository.firstPageOfSurah(surahNumber);
      emit(SurahReadingLoadedState(
        startingPageNumber: pageNumber,
        totalPages: kQuranTotalPages,
      ));
    } catch (_) {
      emit(const SurahReadingUnavailableState());
    }
  }

  /// Resolves a Juz's first page for the jump sheet's Juz tab. Does not
  /// emit — the caller is responsible for driving the `PageController`
  /// (contracts/surah_reading_cubit_contract.md).
  Future<int> resolveJuzFirstPage(int juzNumber) =>
      _repository.firstPageOfJuz(juzNumber);
}
