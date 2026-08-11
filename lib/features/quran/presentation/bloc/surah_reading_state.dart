import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';

sealed class SurahReadingState {
  const SurahReadingState();
}

class SurahReadingInitialState extends SurahReadingState {
  const SurahReadingInitialState();
}

class SurahReadingLoadingState extends SurahReadingState {
  const SurahReadingLoadingState();
}

class SurahReadingLoadedState extends SurahReadingState {
  final Surah surah;
  final List<Ayah> ayahs;

  const SurahReadingLoadedState({required this.surah, required this.ayahs});
}

/// Neither the remote source nor the bundled local fallback could produce
/// this Surah's text (FR-018).
class SurahReadingUnavailableState extends SurahReadingState {
  const SurahReadingUnavailableState();
}
