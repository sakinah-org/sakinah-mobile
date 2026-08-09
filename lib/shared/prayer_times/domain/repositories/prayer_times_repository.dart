import '../entities/calculation_method.dart';
import '../entities/prayer_location.dart';
import '../entities/prayer_times.dart';

abstract class PrayerTimesRepository {
  /// Single method regardless of source — callers MUST resolve a
  /// [PrayerLocation] via [resolveLocation] first; this method assumes one
  /// is already available. Throws a [Failure] subclass (see
  /// lib/configurations/app_errors.dart) mapped from any network error when
  /// neither a fresh fetch nor a cached response is available.
  Future<PrayerTimes> getPrayerTimes({
    required PrayerLocation location,
    required CalculationMethod method,
    required DateTime date,
  });

  /// Resolves the location to use: last-stored lat/lng if present,
  /// otherwise attempts device geolocation (permission + position read) and
  /// persists it on success. Returns null when nothing is resolvable.
  Future<Coordinates?> resolveLocation({bool forceRedetect = false});

  Future<CalculationMethod> getStoredCalculationMethod();

  Future<void> storeCalculationMethod(CalculationMethod method);
}
