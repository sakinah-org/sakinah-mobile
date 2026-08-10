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

/// Human-readable city/country for the Prayers screen's location card
/// (specs/003-prayers-times-screen/spec.md FR-001) — display only, never
/// used for prayer-time calculation. Produced by
/// [PrayerTimesRepository.resolveDisplayLocation].
class ResolvedLocationLabel {
  final String city;
  final String country;

  const ResolvedLocationLabel({required this.city, required this.country});

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
      };

  static ResolvedLocationLabel fromJson(Map json) => ResolvedLocationLabel(
        city: json['city'] as String,
        country: json['country'] as String,
      );
}
