import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../configurations/app_end_points.dart';
import '../../../../configurations/app_errors.dart';
import '../../../../configurations/app_persistence_data_keys.dart';
import '../../../../handlers/shared_handler.dart';
import '../../../../network/network_handler.dart';
import '../../../../network/request_instructions.dart';
import '../../domain/entities/ayah_of_today.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../models/ayah_of_today_model.dart';

class AyahRepositoryImpl implements AyahRepository {
  AyahRepositoryImpl({
    DioClient? dioClient,
    SharedPrefHandler? prefs,
    Random? random,
  })  : _dio = dioClient ?? DioClient.instance,
        _prefs = prefs ?? SharedPrefHandler.instance!,
        _random = random ?? Random();

  final DioClient _dio;
  final SharedPrefHandler _prefs;
  final Random _random;

  @override
  Future<AyahOfToday> getAyahOfToday() async {
    final today = DateTime.now();
    final cached = _readCache();

    // Same-day cache hit — skip the network call entirely.
    if (cached != null && cached.ayah.isFromToday(today)) {
      return cached.ayah;
    }

    // Global ayah index across the whole Quran (1-6236), generated
    // client-side per contracts/ayah_of_today_api.md.
    final globalAyahNumber = 1 + _random.nextInt(6236);
    try {
      final response = await _dio.request(RequestInstructions(
        url: AppEndPoints.quranCloudAyah(globalAyahNumber),
        method: 'GET',
      ));

      final ayah = AyahOfTodayModel.fromAlQuranCloudJson(
        response.data as Map<String, dynamic>,
        globalAyahNumber,
        today,
      );

      await _prefs.save(
        AppPersistenceDataKeys.ayahOfTodayCache,
        value: CachedAyah(ayah: ayah).toJson(),
      );

      return ayah;
    } on DioException catch (e) {
      final failure = Failure.handleDioException(e);
      // Stale cache from any prior day is still shown, labeled by the
      // caller via AyahOfToday.isFromToday (FR-013).
      if (cached != null) return cached.ayah;
      throw failure;
    }
  }

  CachedAyah? _readCache() {
    if (!_prefs.contains(AppPersistenceDataKeys.ayahOfTodayCache)) {
      return null;
    }
    try {
      final raw = _prefs.get<Map>(key: AppPersistenceDataKeys.ayahOfTodayCache);
      return CachedAyah.fromJson(raw);
    } catch (_) {
      return null;
    }
  }
}
