import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/presentation/bloc/surah_reading_cubit.dart';
import 'package:sakinah/features/quran/presentation/bloc/surah_reading_state.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

void main() {
  late MockQuranRepository repository;

  setUp(() {
    repository = MockQuranRepository();
  });

  group('initialize', () {
    blocTest<SurahReadingCubit, SurahReadingState>(
      'emits [Loading, Loaded] with the Surah\'s first page and the fixed total',
      setUp: () {
        when(() => repository.firstPageOfSurah(2)).thenAnswer((_) async => 2);
      },
      build: () => SurahReadingCubit(repository: repository),
      act: (cubit) => cubit.initialize(2),
      expect: () => [
        isA<SurahReadingLoadingState>(),
        isA<SurahReadingLoadedState>()
            .having((s) => s.startingPageNumber, 'startingPageNumber', 2)
            .having((s) => s.totalPages, 'totalPages', kQuranTotalPages),
      ],
    );

    blocTest<SurahReadingCubit, SurahReadingState>(
      'emits [Loading, Unavailable] when page resolution fails',
      setUp: () {
        when(() => repository.firstPageOfSurah(1)).thenThrow(Exception('boom'));
      },
      build: () => SurahReadingCubit(repository: repository),
      act: (cubit) => cubit.initialize(1),
      expect: () => [
        isA<SurahReadingLoadingState>(),
        isA<SurahReadingUnavailableState>(),
      ],
    );
  });

  group('resolveJuzFirstPage', () {
    test('returns the repository\'s resolved page without emitting', () async {
      when(() => repository.firstPageOfJuz(5)).thenAnswer((_) async => 82);
      final cubit = SurahReadingCubit(repository: repository);

      final page = await cubit.resolveJuzFirstPage(5);

      expect(page, 82);
      expect(cubit.state, isA<SurahReadingInitialState>());
    });
  });
}
