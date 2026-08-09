import 'dart:developer';

import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` for a one-shot device-coordinates read.
/// Permission grant/deny is owned by [PermissionHandler] — this class only
/// reads the position once permission is already known to be granted.
class LocationHandler {
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (e) {
      log('LocationHandler.getCurrentPosition failed: $e');
      return null;
    }
  }
}
