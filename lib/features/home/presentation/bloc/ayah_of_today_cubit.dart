import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/ayah_repository_impl.dart';
import '../../domain/repositories/ayah_repository.dart';
import 'ayah_of_today_state.dart';

/// Home-scoped (not a singleton) — single consumer today, provided via
/// `BlocProvider` at `HomePage` per Principle II ("do not make
/// feature-local, per-screen state a singleton").
class AyahOfTodayCubit extends Cubit<AyahOfTodayState> {
  AyahOfTodayCubit({AyahRepository? repository})
      : _repository = repository ?? AyahRepositoryImpl(),
        super(const AyahOfTodayInitialState());

  final AyahRepository _repository;

  Future<void> loadAyahOfToday() async {
    emit(const AyahOfTodayLoadingState());
    await _load();
  }

  Future<void> retry() => loadAyahOfToday();

  Future<void> _load() async {
    try {
      final ayah = await _repository.getAyahOfToday();
      emit(AyahOfTodayLoadedState(
        ayah,
        isFromToday: ayah.isFromToday(DateTime.now()),
      ));
    } catch (e) {
      log('AyahOfTodayCubit._load failed: $e');
      emit(const AyahOfTodayUnavailableState());
    }
  }
}
