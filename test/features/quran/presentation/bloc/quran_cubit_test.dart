import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/features/quran/domain/entities/juz_section.dart';
import 'package:sakinah/features/quran/domain/entities/surah.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/presentation/bloc/quran_cubit.dart';
import 'package:sakinah/features/quran/presentation/bloc/quran_state.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

List<Surah> _sampleSurahs() => const [
      Surah(
        number: 1,
        arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
        transliteration: 'Al-Faatiha',
        meaning: 'The Opening',
        revelationType: RevelationType.meccan,
        ayahCount: 7,
      ),
      Surah(
        number: 2,
        arabicName: 'سُورَةُ البَقَرَةِ',
        transliteration: 'Al-Baqara',
        meaning: 'The Cow',
        revelationType: RevelationType.medinan,
        ayahCount: 286,
      ),
    ];

Future<QuranCubit> _loadedCubit(MockQuranRepository repository) async {
  when(() => repository.getSurahList())
      .thenAnswer((_) async => _sampleSurahs());
  final cubit = QuranCubit(repository: repository);
  await cubit.loadSurahs();
  return cubit;
}

void main() {
  late MockQuranRepository repository;

  setUp(() {
    repository = MockQuranRepository();
  });

  group('loadSurahs', () {
    blocTest<QuranCubit, QuranState>(
      'emits [Loading, Loaded] with the Surah tab active on success',
      setUp: () {
        when(() => repository.getSurahList())
            .thenAnswer((_) async => _sampleSurahs());
      },
      build: () => QuranCubit(repository: repository),
      act: (cubit) => cubit.loadSurahs(),
      expect: () => [
        isA<QuranLoadingState>(),
        isA<QuranLoadedState>()
            .having((s) => s.surahs, 'surahs', hasLength(2))
            .having((s) => s.activeTab, 'activeTab', QuranTab.surah)
            .having((s) => s.juzSections, 'juzSections', isEmpty),
      ],
    );

    blocTest<QuranCubit, QuranState>(
      'emits [Loading, Unavailable] when the repository throws',
      setUp: () {
        when(() => repository.getSurahList()).thenThrow(Exception('boom'));
      },
      build: () => QuranCubit(repository: repository),
      act: (cubit) => cubit.loadSurahs(),
      expect: () => [
        isA<QuranLoadingState>(),
        isA<QuranUnavailableState>(),
      ],
    );
  });

  group('switchTab', () {
    final juzSections = [
      JuzSection(juzNumber: 1, surahs: [_sampleSurahs().first]),
    ];

    blocTest<QuranCubit, QuranState>(
      'fetches Juz sections only the first time the Juz tab is opened',
      setUp: () {
        when(() => repository.getSurahList())
            .thenAnswer((_) async => _sampleSurahs());
        when(() => repository.getJuzSections())
            .thenAnswer((_) async => juzSections);
      },
      build: () => QuranCubit(repository: repository),
      act: (cubit) async {
        await cubit.loadSurahs();
        await cubit.switchTab(QuranTab.juz);
        await cubit.switchTab(QuranTab.surah);
        await cubit.switchTab(QuranTab.juz);
      },
      verify: (_) {
        verify(() => repository.getJuzSections()).called(1);
      },
      expect: () => [
        isA<QuranLoadingState>(),
        isA<QuranLoadedState>()
            .having((s) => s.activeTab, 'tab', QuranTab.surah),
        isA<QuranLoadedState>()
            .having((s) => s.activeTab, 'tab', QuranTab.juz)
            .having((s) => s.juzSections, 'juzSections', juzSections),
        isA<QuranLoadedState>()
            .having((s) => s.activeTab, 'tab', QuranTab.surah),
        isA<QuranLoadedState>().having((s) => s.activeTab, 'tab', QuranTab.juz),
      ],
    );
  });

  group('search / clearSearch', () {
    test('matches by transliteration, case-insensitively', () async {
      final cubit = await _loadedCubit(repository);

      cubit.search('baqa');

      final state = cubit.state as QuranLoadedState;
      expect(state.searchQuery, 'baqa');
      expect(state.searchResults, hasLength(1));
      expect(state.searchResults!.first.number, 2);
    });

    test('matches by Arabic name', () async {
      final cubit = await _loadedCubit(repository);

      cubit.search('الفاتحة');

      final state = cubit.state as QuranLoadedState;
      expect(state.searchResults, hasLength(1));
      expect(state.searchResults!.first.number, 1);
    });

    test('does NOT match the English meaning', () async {
      final cubit = await _loadedCubit(repository);

      cubit.search('Opening');

      final state = cubit.state as QuranLoadedState;
      expect(state.searchResults, isEmpty);
    });

    test('a non-matching query yields an empty (not null) result list',
        () async {
      final cubit = await _loadedCubit(repository);

      cubit.search('zzz');

      final state = cubit.state as QuranLoadedState;
      expect(state.searchQuery, 'zzz');
      expect(state.searchResults, isNotNull);
      expect(state.searchResults, isEmpty);
    });

    test('clearSearch restores the previously active tab and clears search',
        () async {
      when(() => repository.getJuzSections()).thenAnswer((_) async => const []);
      final cubit = await _loadedCubit(repository);
      await cubit.switchTab(QuranTab.juz);
      cubit.search('baqa');

      cubit.clearSearch();

      final state = cubit.state as QuranLoadedState;
      expect(state.searchQuery, isNull);
      expect(state.searchResults, isNull);
      expect(state.activeTab, QuranTab.juz);
    });
  });
}
