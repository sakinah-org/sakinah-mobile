import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/quran_repository.dart';
import 'surah_reading_state.dart';

/// Feature-scoped (not a singleton) — provided via `BlocProvider` at
/// `SurahReadingPage` only, one instance per screen visit. See
/// contracts/surah_reading_cubit_contract.md.
class SurahReadingCubit extends Cubit<SurahReadingState> {
  SurahReadingCubit({required QuranRepository repository})
      : _repository = repository,
        super(const SurahReadingInitialState());

  final QuranRepository _repository;

  Future<void> loadSurah(int surahNumber) async {
    emit(const SurahReadingLoadingState());
    try {
      final surahs = await _repository.getSurahList();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await _repository.getSurah(surahNumber);
      emit(SurahReadingLoadedState(surah: surah, ayahs: ayahs));
    } catch (_) {
      emit(const SurahReadingUnavailableState());
    }
  }
}
