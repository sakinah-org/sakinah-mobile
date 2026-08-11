import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/features/qibla/domain/entities/qibla_reading.dart';
import 'package:sakinah/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:sakinah/features/qibla/presentation/bloc/qibla_compass_cubit.dart';
import 'package:sakinah/features/qibla/presentation/bloc/qibla_compass_state.dart';

class MockQiblaRepository extends Mock implements QiblaRepository {}

void main() {
  late MockQiblaRepository repository;

  setUp(() {
    repository = MockQiblaRepository();
  });

  group('load — live sensor path', () {
    blocTest<QiblaCompassCubit, QiblaCompassState>(
      'emits Loading then an initial Live state, then further Live states from the stream',
      setUp: () {
        when(() => repository.hasCompassSensor()).thenAnswer((_) async => true);
        when(() => repository.getBearing()).thenAnswer(
          (_) async => const QiblaLiveReading(
            bearingDegrees: 120,
            headingDegrees: 0,
            accuracy: CompassAccuracy.unknown,
          ),
        );
        when(() => repository.watchLiveBearing()).thenAnswer(
          (_) => Stream.value(const QiblaLiveReading(
            bearingDegrees: 120,
            headingDegrees: 45,
            accuracy: CompassAccuracy.good,
          )),
        );
      },
      build: () => QiblaCompassCubit(repository: repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaLoadingState(),
        isA<QiblaLiveState>()
            .having((s) => s.reading.headingDegrees, 'headingDegrees', 0),
        isA<QiblaLiveState>()
            .having((s) => s.reading.headingDegrees, 'headingDegrees', 45)
            .having(
                (s) => s.reading.accuracy, 'accuracy', CompassAccuracy.good),
      ],
    );
  });

  group('load — no magnetometer', () {
    blocTest<QiblaCompassCubit, QiblaCompassState>(
      'emits Loading then a Static state, never subscribes to the live stream',
      setUp: () {
        when(() => repository.hasCompassSensor())
            .thenAnswer((_) async => false);
        when(() => repository.getBearing()).thenAnswer(
          (_) async => const QiblaStaticReading(bearingDegrees: 245),
        );
      },
      build: () => QiblaCompassCubit(repository: repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaLoadingState(),
        isA<QiblaStaticState>()
            .having((s) => s.reading.bearingDegrees, 'bearingDegrees', 245),
      ],
      verify: (_) {
        verifyNever(() => repository.watchLiveBearing());
      },
    );
  });

  group('load — location unavailable', () {
    blocTest<QiblaCompassCubit, QiblaCompassState>(
      'emits Loading then LocationRequired',
      setUp: () {
        when(() => repository.hasCompassSensor()).thenAnswer((_) async => true);
        when(() => repository.getBearing()).thenAnswer((_) async => null);
      },
      build: () => QiblaCompassCubit(repository: repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const QiblaLoadingState(),
        const QiblaLocationRequiredState(),
      ],
    );
  });

  group('retry', () {
    blocTest<QiblaCompassCubit, QiblaCompassState>(
      're-runs the same resolution flow as load()',
      setUp: () {
        when(() => repository.hasCompassSensor())
            .thenAnswer((_) async => false);
        when(() => repository.getBearing()).thenAnswer(
          (_) async => const QiblaStaticReading(bearingDegrees: 10),
        );
      },
      build: () => QiblaCompassCubit(repository: repository),
      act: (cubit) => cubit.retry(),
      expect: () => [
        const QiblaLoadingState(),
        isA<QiblaStaticState>(),
      ],
    );
  });
}
