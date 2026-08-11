import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/qibla_repository_impl.dart';
import '../../domain/entities/qibla_reading.dart';
import '../../domain/repositories/qibla_repository.dart';
import 'qibla_compass_state.dart';

/// Not a singleton — one consumer (`QiblaCompassPage`), constructed and
/// provided per-screen via `BlocProvider` (Constitution Principle II:
/// feature-local, per-screen state is not a singleton), same reasoning as
/// `AyahOfTodayCubit`. contracts/qibla_repository_and_cubit_contract.md
class QiblaCompassCubit extends Cubit<QiblaCompassState> {
  QiblaCompassCubit({QiblaRepository? repository})
      : _repository = repository ?? QiblaRepositoryImpl(),
        super(const QiblaInitialState());

  final QiblaRepository _repository;
  StreamSubscription<QiblaLiveReading>? _liveSub;

  Future<void> load() async {
    emit(const QiblaLoadingState());
    await _resolve();
  }

  /// Re-runs the same flow as [load] — used only from the
  /// `QiblaLocationRequiredState` UI's retry/grant-access action.
  Future<void> retry() => load();

  Future<void> _resolve() async {
    final hasSensor = await _repository.hasCompassSensor();
    final reading = await _repository.getBearing();

    if (reading == null) {
      emit(const QiblaLocationRequiredState());
      return;
    }

    if (!hasSensor) {
      final bearing = switch (reading) {
        QiblaStaticReading(:final bearingDegrees) => bearingDegrees,
        QiblaLiveReading(:final bearingDegrees) => bearingDegrees,
      };
      emit(QiblaStaticState(QiblaStaticReading(bearingDegrees: bearing)));
      return;
    }

    emit(QiblaLiveState(reading as QiblaLiveReading));
    await _liveSub?.cancel();
    _liveSub = _repository.watchLiveBearing().listen((liveReading) {
      emit(QiblaLiveState(liveReading));
    });
  }

  @override
  Future<void> close() {
    _liveSub?.cancel();
    return super.close();
  }
}
