import 'dart:developer';

import 'package:geocoding/geocoding.dart';

/// Thin wrapper around `geocoding`'s static API, mirroring
/// [LocationHandler]'s shape — exists purely as a constructor-DI seam so
/// callers (e.g. `PrayerTimesRepositoryImpl`) stay unit-testable with
/// `mocktail`, since the `geocoding` package itself exposes only top-level
/// functions, not an injectable class.
class GeocodingHandler {
  Future<List<Placemark>> placemarksFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Constructed lazily (not as a field) so that touching this handler
      // never throws until a geocode is actually attempted — the platform
      // interface it needs isn't registered in a plain unit-test
      // environment, and that's a caught/fallback case, not a crash.
      return await Geocoding().placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      log('GeocodingHandler.placemarksFromCoordinates failed: $e');
      return const [];
    }
  }
}
