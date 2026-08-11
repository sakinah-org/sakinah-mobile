import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/features/quran/domain/entities/ayah.dart';
import 'package:sakinah/features/quran/domain/entities/surah.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/presentation/bloc/surah_reading_cubit.dart';
import 'package:sakinah/features/quran/presentation/bloc/surah_reading_state.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

const _fatiha = Surah(
  number: 1,
  arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
  transliteration: 'Al-Faatiha',
  meaning: 'The Opening',
  revelationType: RevelationType.meccan,
  ayahCount: 7,
);

void main() {
  late MockQuranRepository repository;

  setUp(() {
    repository = MockQuranRepository();
  });

  group('loadSurah', () {
    blocTest<SurahReadingCubit, SurahReadingState>(
      'emits [Loading, Loaded] with the matching Surah and its ayahs',
      setUp: () {
        when(() => repository.getSurahList())
            .thenAnswer((_) async => const [_fatiha]);
        when(() => repository.getSurah(1)).thenAnswer((_) async => const [
              Ayah(
                  numberInSurah: 1,
                  text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
            ]);
      },
      build: () => SurahReadingCubit(repository: repository),
      act: (cubit) => cubit.loadSurah(1),
      expect: () => [
        isA<SurahReadingLoadingState>(),
        isA<SurahReadingLoadedState>()
            .having((s) => s.surah.number, 'surah.number', 1)
            .having((s) => s.ayahs, 'ayahs', hasLength(1)),
      ],
    );

    blocTest<SurahReadingCubit, SurahReadingState>(
      'emits [Loading, Unavailable] when the ayah fetch fails',
      setUp: () {
        when(() => repository.getSurahList())
            .thenAnswer((_) async => const [_fatiha]);
        when(() => repository.getSurah(1)).thenThrow(Exception('boom'));
      },
      build: () => SurahReadingCubit(repository: repository),
      act: (cubit) => cubit.loadSurah(1),
      expect: () => [
        isA<SurahReadingLoadingState>(),
        isA<SurahReadingUnavailableState>(),
      ],
    );
  });
}
