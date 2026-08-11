import '../entities/qibla_reading.dart';

/// contracts/qibla_repository_and_cubit_contract.md
abstract class QiblaRepository {
  /// Resolves user coordinates (research.md R8) and returns a
  /// [QiblaReading] — a [QiblaStaticReading] when no compass sensor is
  /// available, or an initial [QiblaLiveReading] otherwise — or `null` if
  /// location is unavailable (permission denied / services off).
  Future<QiblaReading?> getBearing();

  /// True if the device has no usable magnetometer for a live compass.
  /// Checked once per screen visit before deciding whether to subscribe to
  /// [watchLiveBearing].
  Future<bool> hasCompassSensor();

  /// Live stream of heading + accuracy updates, only meaningful when
  /// [hasCompassSensor] resolved `true`. The cubit subscribes while the
  /// Qibla Compass screen is visible and cancels on dispose.
  Stream<QiblaLiveReading> watchLiveBearing();
}
