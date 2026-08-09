import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/features/home/domain/entities/ayah_of_today.dart';
import 'package:sakinah/features/home/domain/repositories/ayah_repository.dart';
import 'package:sakinah/features/home/presentation/bloc/ayah_of_today_cubit.dart';
import 'package:sakinah/features/home/presentation/bloc/ayah_of_today_state.dart';

class MockAyahRepository extends Mock implements AyahRepository {}

void main() {
  late MockAyahRepository repository;

  setUp(() {
    repository = MockAyahRepository();
  });

  final todayAyah = AyahOfToday(
    arabicText: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    translation: 'Verily, in the remembrance of Allah do hearts find rest.',
    surahNumber: 13,
    surahName: "Ar-Ra'd",
    ayahNumberInSurah: 28,
    globalAyahNumber: 2130,
    selectedForDate: DateTime.now(),
  );

  final staleAyah = AyahOfToday(
    arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
    translation: 'Say, He is Allah, [who is] One.',
    surahNumber: 112,
    surahName: 'Al-Ikhlas',
    ayahNumberInSurah: 1,
    globalAyahNumber: 6222,
    selectedForDate: DateTime(2000, 1, 1),
  );

  blocTest<AyahOfTodayCubit, AyahOfTodayState>(
    'loadAyahOfToday emits [Loading, Loaded(isFromToday:true)] on success',
    setUp: () {
      when(() => repository.getAyahOfToday())
          .thenAnswer((_) async => todayAyah);
    },
    build: () => AyahOfTodayCubit(repository: repository),
    act: (cubit) => cubit.loadAyahOfToday(),
    expect: () => [
      isA<AyahOfTodayLoadingState>(),
      isA<AyahOfTodayLoadedState>()
          .having((s) => s.isFromToday, 'isFromToday', isTrue),
    ],
  );

  blocTest<AyahOfTodayCubit, AyahOfTodayState>(
    'loadAyahOfToday emits [Loading, Loaded(isFromToday:false)] for a stale cached ayah',
    setUp: () {
      when(() => repository.getAyahOfToday())
          .thenAnswer((_) async => staleAyah);
    },
    build: () => AyahOfTodayCubit(repository: repository),
    act: (cubit) => cubit.loadAyahOfToday(),
    expect: () => [
      isA<AyahOfTodayLoadingState>(),
      isA<AyahOfTodayLoadedState>()
          .having((s) => s.isFromToday, 'isFromToday', isFalse),
    ],
  );

  blocTest<AyahOfTodayCubit, AyahOfTodayState>(
    'loadAyahOfToday emits [Loading, Unavailable] when the repository throws',
    setUp: () {
      when(() => repository.getAyahOfToday())
          .thenThrow(Exception('no cache, network down'));
    },
    build: () => AyahOfTodayCubit(repository: repository),
    act: (cubit) => cubit.loadAyahOfToday(),
    expect: () => [
      isA<AyahOfTodayLoadingState>(),
      isA<AyahOfTodayUnavailableState>(),
    ],
  );

  blocTest<AyahOfTodayCubit, AyahOfTodayState>(
    'retry() calls the repository again and can recover to Loaded',
    setUp: () {
      when(() => repository.getAyahOfToday())
          .thenAnswer((_) async => todayAyah);
    },
    build: () => AyahOfTodayCubit(repository: repository),
    act: (cubit) => cubit.retry(),
    expect: () => [
      isA<AyahOfTodayLoadingState>(),
      isA<AyahOfTodayLoadedState>(),
    ],
    verify: (_) {
      verify(() => repository.getAyahOfToday()).called(1);
    },
  );
}
