import 'package:dio/dio.dart';

import '../../../../configurations/app_end_points.dart';
import '../../../../configurations/app_errors.dart';
import '../../../../configurations/app_persistence_data_keys.dart';
import '../../../../handlers/location_handler.dart';
import '../../../../handlers/permission_handler.dart';
import '../../../../handlers/shared_handler.dart';
import '../../../../network/network_handler.dart';
import '../../../../network/request_instructions.dart';
import '../../domain/entities/calculation_method.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../models/prayer_times_model.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl({
    DioClient? dioClient,
    SharedPrefHandler? prefs,
    LocationHandler? locationHandler,
    PermissionHandler? permissionHandler,
  })  : _dio = dioClient ?? DioClient.instance,
        _prefs = prefs ?? SharedPrefHandler.instance!,
        _locationHandler = locationHandler ?? LocationHandler(),
        _permissionHandler = permissionHandler ?? PermissionHandler();

  final DioClient _dio;
  final SharedPrefHandler _prefs;
  final LocationHandler _locationHandler;
  final PermissionHandler _permissionHandler;

  @override
  Future<Coordinates?> resolveLocation({bool forceRedetect = false}) async {
    if (!forceRedetect &&
        _prefs.contains(AppPersistenceDataKeys.prayerLocationLat) &&
        _prefs.contains(AppPersistenceDataKeys.prayerLocationLng)) {
      return Coordinates(
        latitude:
            _prefs.get<double>(key: AppPersistenceDataKeys.prayerLocationLat),
        longitude:
            _prefs.get<double>(key: AppPersistenceDataKeys.prayerLocationLng),
      );
    }

    final granted = await _permissionHandler.checkLocationPermission();
    if (!granted) return null;

    final position = await _locationHandler.getCurrentPosition();
    if (position == null) return null;

    await _prefs.save(AppPersistenceDataKeys.prayerLocationLat,
        value: position.latitude);
    await _prefs.save(AppPersistenceDataKeys.prayerLocationLng,
        value: position.longitude);

    return Coordinates(
        latitude: position.latitude, longitude: position.longitude);
  }

  @override
  Future<CalculationMethod> getStoredCalculationMethod() async {
    if (!_prefs.contains(AppPersistenceDataKeys.prayerCalculationMethod)) {
      return CalculationMethod.fallback;
    }
    return CalculationMethod.fromStoredValue(_prefs.get<String>(
        key: AppPersistenceDataKeys.prayerCalculationMethod));
  }

  @override
  Future<void> storeCalculationMethod(CalculationMethod method) async {
    await _prefs.save(AppPersistenceDataKeys.prayerCalculationMethod,
        value: method.storedValue);
  }

  @override
  Future<PrayerTimes> getPrayerTimes({
    required PrayerLocation location,
    required CalculationMethod method,
    required DateTime date,
  }) async {
    final signature = _signatureOf(location, method);
    final cached = _readCache();

    // Same day + same location + same method already cached — skip the
    // network call entirely (mirrors the Ayah-of-Today same-day cache hit).
    if (cached != null &&
        _isSameDate(cached.prayerTimes.date, date) &&
        cached.locationSignature == signature) {
      return cached.prayerTimes;
    }

    final dateStr = _formatDate(date);
    try {
      final response = await _dio.request(RequestInstructions(
        url: location is City
            ? AppEndPoints.alAdhanTimingsByCity(dateStr)
            : AppEndPoints.alAdhanTimingsByCoordinates(dateStr),
        method: 'GET',
        queryParameters: {
          if (location is Coordinates) 'latitude': location.latitude,
          if (location is Coordinates) 'longitude': location.longitude,
          if (location is City) 'city': location.city,
          'method': method.alAdhanId,
          'school': 0,
        },
      ));

      final times = PrayerTimesModel.fromAlAdhanJson(
        response.data as Map<String, dynamic>,
        date,
      );

      await _prefs.save(
        AppPersistenceDataKeys.prayerTimesCache,
        value: CachedPrayerTimes(
          prayerTimes: times,
          locationSignature: signature,
          fetchedAt: DateTime.now(),
        ).toJson(),
      );

      return times;
    } on DioException catch (e) {
      final failure = Failure.handleDioException(e);
      // Fall back to whatever was last cached, regardless of its date or
      // location/method signature (FR-007 always allows showing something).
      if (cached != null) return cached.prayerTimes;
      throw failure;
    }
  }

  CachedPrayerTimes? _readCache() {
    if (!_prefs.contains(AppPersistenceDataKeys.prayerTimesCache)) {
      return null;
    }
    try {
      final raw = _prefs.get<Map>(key: AppPersistenceDataKeys.prayerTimesCache);
      return CachedPrayerTimes.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  String _signatureOf(PrayerLocation location, CalculationMethod method) {
    final locationPart = switch (location) {
      Coordinates() => location.signature,
      City() => location.signature,
    };
    return '$locationPart|${method.storedValue}';
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }
}
