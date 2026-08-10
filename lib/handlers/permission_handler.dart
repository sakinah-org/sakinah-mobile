import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  Future<bool> _checkPermission(Permission permission) async {
    var status = await permission.status;
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
        var response = await permission.request();
        return response.isGranted;
      case PermissionStatus.permanentlyDenied:
        return false;
      default:
        return false;
    }
  }

  Future<bool> checkCameraPermission() async {
    return await _checkPermission(Permission.camera);
  }

  Future<bool> checkStoragePermission() async {
    return await _checkPermission(Permission.storage);
  }

  Future<bool> checkLocationPermission() async {
    return await _checkPermission(Permission.location);
  }

  Future<bool> checkContactsPermission() async {
    return await _checkPermission(Permission.contacts);
  }

  /// Notification permission as a tri-state, unlike [_checkPermission]'s
  /// bool (which collapses denied/permanentlyDenied) — the Prayers screen
  /// needs to tell those two apart (FR-013 vs FR-014, research.md R4).
  /// Requests the OS prompt when not yet determined, same as
  /// [_checkPermission]'s existing denied-branch behavior.
  Future<PermissionStatus> checkNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (status == PermissionStatus.denied) {
      return await Permission.notification.request();
    }
    return status;
  }

  Future<void> openAppNotificationSettings() => openAppSettings();
}
