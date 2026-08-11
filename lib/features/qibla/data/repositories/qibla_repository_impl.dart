import 'dart:async';
import 'dart:math' show atan2, cos, pi, sin, sqrt;

import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

import '../../../../handlers/location_handler.dart';
import '../../../../handlers/permission_handler.dart';
import '../../domain/entities/qibla_reading.dart';
import '../../domain/repositories/qibla_repository.dart';

/// Kaaba coordinates — identical to the constants `flutter_qiblah` itself
/// uses internally (its own `Utils.getOffsetFromNorth` is `src`-private and
/// not exported, so the static-bearing formula below is reimplemented here;
/// research.md R7) — kept equal so the live and static bearings never
/// disagree.
const double _kaabaLatitude = 21.422487;
const double _kaabaLongitude = 39.826206;

/// `CompassEvent.accuracy` threshold (degrees) above which the calibration
/// prompt is shown (research.md R7) — a reasonable default, not a hard
/// external spec.
const double _lowAccuracyThresholdDegrees = 15;

class QiblaRepositoryImpl implements QiblaRepository {
  QiblaRepositoryImpl({
    LocationHandler? locationHandler,
    PermissionHandler? permissionHandler,
  })  : _locationHandler = locationHandler ?? LocationHandler(),
        _permissionHandler = permissionHandler ?? PermissionHandler();

  final LocationHandler _locationHandler;
  final PermissionHandler _permissionHandler;

  /// Distance barely changes across a single Qibla-checking session (the
  /// user is rotating in place, not travelling), so it is computed once in
  /// [getBearing] and reused by every subsequent [watchLiveBearing] emission
  /// rather than requiring a fresh position fix per compass tick.
  double? _cachedDistanceKm;

  @override
  Future<bool> hasCompassSensor() async {
    // Android-only check per the plugin; iOS devices are assumed to have a
    // working magnetometer (flutter_qiblah does not run on the iOS
    // Simulator at all — research.md R6).
    final supported = await FlutterQiblah.androidDeviceSensorSupport();
    return supported ?? true;
  }

  @override
  Future<QiblaReading?> getBearing() async {
    final granted = await _permissionHandler.checkLocationPermission();
    if (!granted) return null;

    final position = await _locationHandler.getCurrentPosition();
    if (position == null) return null;

    final bearing = _greatCircleBearing(position.latitude, position.longitude);
    _cachedDistanceKm =
        _haversineDistanceKm(position.latitude, position.longitude);

    if (!await hasCompassSensor()) {
      return QiblaStaticReading(
          bearingDegrees: bearing, distanceKm: _cachedDistanceKm);
    }

    // Confirms location resolves; QiblaCompassCubit subscribes to
    // watchLiveBearing() immediately after for actual live heading/accuracy.
    return QiblaLiveReading(
      bearingDegrees: bearing,
      headingDegrees: 0,
      accuracy: CompassAccuracy.unknown,
      distanceKm: _cachedDistanceKm,
    );
  }

  @override
  Stream<QiblaLiveReading> watchLiveBearing() {
    late StreamController<QiblaLiveReading> controller;
    StreamSubscription<CompassEvent>? compassSub;
    StreamSubscription<QiblahDirection>? qiblahSub;
    double? latestAccuracy;

    controller = StreamController<QiblaLiveReading>.broadcast(
      onListen: () {
        compassSub = FlutterCompass.events?.listen((event) {
          latestAccuracy = event.accuracy;
        });
        qiblahSub = FlutterQiblah.qiblahStream.listen((direction) {
          controller.add(QiblaLiveReading(
            bearingDegrees: direction.offset,
            headingDegrees: direction.direction,
            accuracy: _accuracyTier(latestAccuracy),
            distanceKm: _cachedDistanceKm,
          ));
        });
      },
      onCancel: () {
        compassSub?.cancel();
        qiblahSub?.cancel();
      },
    );

    return controller.stream;
  }

  CompassAccuracy _accuracyTier(double? accuracy) {
    if (accuracy == null) return CompassAccuracy.unknown;
    if (accuracy > _lowAccuracyThresholdDegrees) return CompassAccuracy.low;
    return CompassAccuracy.good;
  }

  /// Standard great-circle initial-bearing formula, independent of any
  /// sensor stream (research.md R7) — used for both the static-fallback
  /// reading and as the initial bearing in [getBearing]'s live branch.
  double _greatCircleBearing(
    double fromLatitude,
    double fromLongitude,
  ) {
    final phi1 = fromLatitude * pi / 180;
    const phi2 = _kaabaLatitude * pi / 180;
    final deltaLambda = (_kaabaLongitude - fromLongitude) * pi / 180;

    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final theta = atan2(y, x);

    return (theta * 180 / pi + 360) % 360;
  }

  /// Great-circle (haversine) distance in km — display-only, for the
  /// design's distance-to-Mecca caption.
  double _haversineDistanceKm(double fromLatitude, double fromLongitude) {
    const earthRadiusKm = 6371.0;
    final phi1 = fromLatitude * pi / 180;
    const phi2 = _kaabaLatitude * pi / 180;
    final deltaPhi = (_kaabaLatitude - fromLatitude) * pi / 180;
    final deltaLambda = (_kaabaLongitude - fromLongitude) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}
