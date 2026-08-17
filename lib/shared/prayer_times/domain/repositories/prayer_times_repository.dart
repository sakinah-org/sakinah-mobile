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

  /// Resolves the location to use. When [userId] is given (a signed-in
  /// user), the remote `user_preferences` row is read first — the user may
  /// have changed their location from elsewhere — and the local cache is
  /// only used when that read fails (no network/no row); the fresh remote
  /// value is then persisted locally so offline reads stay accurate. With no
  /// [userId] (guest) or on remote miss, falls back to last-stored lat/lng,
  /// then to device geolocation (permission + position read), persisting on
  /// success. Returns null when nothing is resolvable.
  Future<Coordinates?> resolveLocation(
      {bool forceRedetect = false, String? userId});

  /// When [userId] is given, the remote `user_preferences` row is read
  /// first so a method changed elsewhere (e.g. directly in the database) is
  /// picked up immediately; the local cache is only used when that read
  /// fails (no network/no row), and a successful remote read is persisted
  /// locally so offline reads stay accurate.
  Future<CalculationMethod> getStoredCalculationMethod({String? userId});

  Future<void> storeCalculationMethod(CalculationMethod method);

  /// City/country label for the Prayers screen's location card (FR-001) —
  /// reverse-geocodes [Coordinates] on device (cached against the location's
  /// signature so it isn't re-geocoded every screen open), or returns the
  /// manually-entered [City.city] as-is. Returns null when it cannot be
  /// resolved (research.md R1).
  Future<ResolvedLocationLabel?> resolveDisplayLocation(
      PrayerLocation location);
}
