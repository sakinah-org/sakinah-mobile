/// Sensor-accuracy tier for a live compass reading (data-model.md §3).
/// `unknown` and `low` both drive the calibration prompt (FR-019);
/// `good` hides it.
enum CompassAccuracy { unknown, low, good }

/// A resolved Qibla bearing — either live (sensor-driven) or static
/// (computed once, no sensor available). See data-model.md §3.
sealed class QiblaReading {
  const QiblaReading();
}

/// Bearing + live device heading from a working magnetometer, with the
/// sensor's current accuracy tier (research.md R7).
class QiblaLiveReading extends QiblaReading {
  const QiblaLiveReading({
    required this.bearingDegrees,
    required this.headingDegrees,
    required this.accuracy,
    this.distanceKm,
  });

  /// Angle (0–360, from true north) from the user's location to the Kaaba.
  final double bearingDegrees;

  /// Device heading (0–360, from north).
  final double headingDegrees;

  final CompassAccuracy accuracy;

  /// Great-circle distance to the Kaaba, for the design's distance caption
  /// (not itself a functional requirement — display-only). `null` for the
  /// brief initial reading `QiblaRepository.getBearing()` returns before
  /// the live stream's first event arrives.
  final double? distanceKm;
}

/// A one-time bearing computed independently of any sensor (research.md
/// R7) — used whenever no magnetometer is available.
class QiblaStaticReading extends QiblaReading {
  const QiblaStaticReading({required this.bearingDegrees, this.distanceKm});

  /// Angle (0–360, from true north) from the user's location to the Kaaba.
  final double bearingDegrees;

  final double? distanceKm;
}
