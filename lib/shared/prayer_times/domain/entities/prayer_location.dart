/// Where prayer times are calculated for. A closed union so
/// [PrayerTimesRepository.getPrayerTimes] has one signature regardless of
/// source — see specs/002-home-page/data-model.md.
sealed class PrayerLocation {
  const PrayerLocation();
}

class Coordinates extends PrayerLocation {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  /// Rounded signature used to detect a meaningful location change without
  /// refetching on GPS noise (spec.md FR-017 refetch trigger).
  String get signature =>
      '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
}

/// Defined for forward-compatibility with the future Prayers manual-entry
/// screen (research.md §5) — not constructed anywhere in this feature.
class City extends PrayerLocation {
  final String city;

  const City({required this.city});

  String get signature => city;
}
