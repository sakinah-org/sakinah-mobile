import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/calculation_method.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/prayer_location.dart';
import 'package:sakinah/shared/prayer_times/domain/entities/prayer_times.dart';
import 'package:sakinah/shared/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:sakinah/shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import 'package:sakinah/shared/prayer_times/presentation/bloc/prayer_times_state.dart';

class MockPrayerTimesRepository extends Mock implements PrayerTimesRepository {}

void main() {
  late MockPrayerTimesRepository repository;

  setUpAll(() {
    registerFallbackValue(const Coordinates(latitude: 30, longitude: 31));
    registerFallbackValue(CalculationMethod.ummAlQura);
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repository = MockPrayerTimesRepository();
  });

  final testTimes = PrayerTimes(
    date: DateTime(2026, 8, 9),
    fajr: DateTime(2026, 8, 9, 5, 21),
    dhuhr: DateTime(2026, 8, 9, 12, 12),
    asr: DateTime(2026, 8, 9, 15, 11),
    maghrib: DateTime(2026, 8, 9, 17, 25),
    isha: DateTime(2026, 8, 9, 19, 2),
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'loadPrayerTimes emits [Loading, Loaded(isFallback:false)] on success',
    setUp: () {
      when(() => repository.resolveLocation(forceRedetect: false)).thenAnswer(
          (_) async => const Coordinates(latitude: 30, longitude: 31));
      when(() => repository.getStoredCalculationMethod())
          .thenAnswer((_) async => CalculationMethod.ummAlQura);
      when(() => repository.getPrayerTimes(
            location: any(named: 'location'),
            method: any(named: 'method'),
            date: any(named: 'date'),
          )).thenAnswer((invocation) async => PrayerTimes(
            date: invocation.namedArguments[#date] as DateTime,
            fajr: testTimes.fajr,
            dhuhr: testTimes.dhuhr,
            asr: testTimes.asr,
            maghrib: testTimes.maghrib,
            isha: testTimes.isha,
          ));
    },
    build: () => PrayerTimesCubit.test(repository),
    act: (cubit) => cubit.loadPrayerTimes(),
    expect: () => [
      isA<PrayerTimesLoadingState>(),
      isA<PrayerTimesLoadedState>()
          .having((s) => s.isFallback, 'isFallback', isFalse),
    ],
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'loadPrayerTimes emits [Loading, LocationRequired] when no location resolvable',
    setUp: () {
      when(() => repository.resolveLocation(forceRedetect: false))
          .thenAnswer((_) async => null);
    },
    build: () => PrayerTimesCubit.test(repository),
    act: (cubit) => cubit.loadPrayerTimes(),
    expect: () => [
      isA<PrayerTimesLoadingState>(),
      isA<PrayerTimesLocationRequiredState>(),
    ],
    verify: (_) {
      verifyNever(() => repository.getPrayerTimes(
            location: any(named: 'location'),
            method: any(named: 'method'),
            date: any(named: 'date'),
          ));
    },
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'loadPrayerTimes emits [Loading, Unavailable] when repository throws with no cache',
    setUp: () {
      when(() => repository.resolveLocation(forceRedetect: false)).thenAnswer(
          (_) async => const Coordinates(latitude: 30, longitude: 31));
      when(() => repository.getStoredCalculationMethod())
          .thenAnswer((_) async => CalculationMethod.ummAlQura);
      when(() => repository.getPrayerTimes(
            location: any(named: 'location'),
            method: any(named: 'method'),
            date: any(named: 'date'),
          )).thenThrow(Exception('no cache, network down'));
    },
    build: () => PrayerTimesCubit.test(repository),
    act: (cubit) => cubit.loadPrayerTimes(),
    expect: () => [
      isA<PrayerTimesLoadingState>(),
      isA<PrayerTimesUnavailableState>(),
    ],
  );

  // A response dated safely in the past — never coincides with "today"
  // regardless of when this test suite actually runs.
  final staleTimes = PrayerTimes(
    date: DateTime(2000, 1, 1),
    fajr: DateTime(2000, 1, 1, 5, 21),
    dhuhr: DateTime(2000, 1, 1, 12, 12),
    asr: DateTime(2000, 1, 1, 15, 11),
    maghrib: DateTime(2000, 1, 1, 17, 25),
    isha: DateTime(2000, 1, 1, 19, 2),
  );

  blocTest<PrayerTimesCubit, PrayerTimesState>(
    'loadPrayerTimes marks isFallback:true when the returned times are from a prior day',
    setUp: () {
      when(() => repository.resolveLocation(forceRedetect: false)).thenAnswer(
          (_) async => const Coordinates(latitude: 30, longitude: 31));
      when(() => repository.getStoredCalculationMethod())
          .thenAnswer((_) async => CalculationMethod.ummAlQura);
      when(() => repository.getPrayerTimes(
            location: any(named: 'location'),
            method: any(named: 'method'),
            date: any(named: 'date'),
          )).thenAnswer((_) async => staleTimes);
    },
    build: () => PrayerTimesCubit.test(repository),
    act: (cubit) => cubit.loadPrayerTimes(),
    expect: () => [
      isA<PrayerTimesLoadingState>(),
      isA<PrayerTimesLoadedState>()
          .having((s) => s.isFallback, 'isFallback', isTrue),
    ],
  );

  group('loadLocationCardInfo', () {
    test('resolves location label + calculation method via the repository',
        () async {
      when(() => repository.resolveLocation(forceRedetect: false)).thenAnswer(
          (_) async => const Coordinates(latitude: 30, longitude: 31));
      when(() => repository.getStoredCalculationMethod())
          .thenAnswer((_) async => CalculationMethod.ummAlQura);
      when(() => repository.resolveDisplayLocation(any())).thenAnswer(
          (_) async =>
              const ResolvedLocationLabel(city: 'Cairo', country: 'Egypt'));

      final cubit = PrayerTimesCubit.test(repository);
      final info = await cubit.loadLocationCardInfo();

      expect(info.locationLabel?.city, 'Cairo');
      expect(info.method, CalculationMethod.ummAlQura);
    });

    test('returns a null label when no location is resolvable', () async {
      when(() => repository.resolveLocation(forceRedetect: false))
          .thenAnswer((_) async => null);
      when(() => repository.getStoredCalculationMethod())
          .thenAnswer((_) async => CalculationMethod.ummAlQura);

      final cubit = PrayerTimesCubit.test(repository);
      final info = await cubit.loadLocationCardInfo();

      expect(info.locationLabel, isNull);
      verifyNever(() => repository.resolveDisplayLocation(any()));
    });
  });

  group('PrayerTimes.nextPrayer', () {
    test('returns the next upcoming prayer today', () {
      final now = DateTime(2026, 8, 9, 13, 0); // between Dhuhr and Asr
      final next = testTimes.nextPrayer(now);
      expect(next.code, 'asr');
      expect(next.time, testTimes.asr);
    });

    test('rolls over to tomorrow\'s Fajr once Isha has passed', () {
      final now = DateTime(2026, 8, 9, 20, 0); // after Isha
      final next = testTimes.nextPrayer(now);
      expect(next.code, 'fajr');
      expect(next.time, testTimes.fajr.add(const Duration(days: 1)));
    });
  });
}
