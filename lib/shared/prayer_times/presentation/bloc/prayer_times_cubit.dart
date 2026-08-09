import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_errors.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/entities/calculation_method.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import 'prayer_times_state.dart';

/// Global, singleton Cubit — the only caller of [PrayerTimesRepository] in
/// the app. Home subscribes to it today; a future Prayers settings screen
/// and a future notification scheduler subscribe to it later, per
/// specs/002-home-page/contracts/prayer_times_cubit_contract.md.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit._internal({PrayerTimesRepository? repository})
      : _repository = repository ?? PrayerTimesRepositoryImpl(),
        super(const PrayerTimesInitialState());

  static PrayerTimesCubit instance = PrayerTimesCubit._internal();

  /// Test-only seam for injecting a fake [PrayerTimesRepository] — the
  /// private constructor keeps `.instance` as the real singleton for
  /// production callers, per Principle II's "static instance" pattern.
  @visibleForTesting
  factory PrayerTimesCubit.test(PrayerTimesRepository repository) =>
      PrayerTimesCubit._internal(repository: repository);

  final PrayerTimesRepository _repository;

  Future<void> loadPrayerTimes() async {
    emit(const PrayerTimesLoadingState());
    await _resolveAndFetch();
  }

  Future<void> refreshLocation() async {
    emit(const PrayerTimesLoadingState());
    await _resolveAndFetch(forceRedetect: true);
  }

  Future<void> onCalculationMethodChanged(CalculationMethod method) async {
    emit(const PrayerTimesLoadingState());
    await _repository.storeCalculationMethod(method);
    await _resolveAndFetch();
  }

  Future<void> _resolveAndFetch({bool forceRedetect = false}) async {
    try {
      final coordinates =
          await _repository.resolveLocation(forceRedetect: forceRedetect);
      if (coordinates == null) {
        emit(const PrayerTimesLocationRequiredState());
        return;
      }

      final method = await _repository.getStoredCalculationMethod();
      await _fetch(location: coordinates, method: method);
    } catch (e) {
      log('PrayerTimesCubit._resolveAndFetch failed: $e');
      emit(const PrayerTimesUnavailableState());
    }
  }

  Future<void> _fetch({
    required PrayerLocation location,
    required CalculationMethod method,
  }) async {
    final today = DateTime.now();
    try {
      final times = await _repository.getPrayerTimes(
        location: location,
        method: method,
        date: today,
      );
      final isFallback = !(times.date.year == today.year &&
          times.date.month == today.month &&
          times.date.day == today.day);
      emit(PrayerTimesLoadedState(times, isFallback: isFallback));
    } catch (e) {
      final message = e is Failure ? e.message : null;
      emit(PrayerTimesUnavailableState(message: message));
    }
  }
}
