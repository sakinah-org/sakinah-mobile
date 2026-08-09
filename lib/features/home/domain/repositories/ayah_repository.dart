import '../entities/ayah_of_today.dart';

abstract class AyahRepository {
  /// No params — all cache/fallback logic is internal
  /// (contracts/ayah_of_today_api.md):
  /// 1. Same-day cache hit → return it, no network call.
  /// 2. Otherwise fetch a random ayah (global index 1-6236).
  /// 3. On fetch failure with a stale cache → return it (caller checks
  ///    [AyahOfToday.isFromToday] to know it's not today's verse).
  /// 4. On fetch failure with no cache at all → throws.
  Future<AyahOfToday> getAyahOfToday();
}
