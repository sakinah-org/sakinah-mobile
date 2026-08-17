import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_handler.dart';

/// Wraps `firebase_messaging` for reading the device's FCM registration
/// token and for receiving pushes sent by the `send-prayer-reminders` Edge
/// Function. Same shape as `LocationHandler`/`NotificationHandler`: a plain
/// singleton doing device interaction, not a Cubit.
class FcmHandler {
  FcmHandler._internal();
  static final FcmHandler instance = FcmHandler._internal();

  bool _listenersInitialized = false;

  /// `user_devices.platform` only accepts 'ios'/'android' (DB CHECK
  /// constraint) — other platforms (macOS, etc.) are left unregistered.
  String? get platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  /// Returns the current device's FCM registration token, or null on
  /// unsupported platforms or failure (e.g. no APNs token yet on iOS).
  Future<String?> getToken() async {
    if (platform == null) return null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      // TODO: debug-only log of the raw FCM token — remove once device
      // registration (007-update-login-FCM) is verified in the field.
      log('FcmHandler.getToken: $token');
      return token;
    } catch (e) {
      log('FcmHandler.getToken failed: $e');
      return null;
    }
  }

  /// Wires up delivery of pushes sent by `send-prayer-reminders`, covering
  /// all three states a message can arrive in:
  /// - Foreground: `onMessage` — the OS never auto-displays these, so this
  ///   shows one via `NotificationHandler` manually.
  /// - Background (app backgrounded, user taps the system tray entry):
  ///   `onMessageOpenedApp`.
  /// - Terminated (app was fully killed, user taps the system tray entry,
  ///   which cold-starts the app): `getInitialMessage()`.
  /// Call once, after `NotificationHandler.instance.init()` so its channel
  /// already exists. Does not request notification permission — that stays
  /// on `PermissionHandler.checkNotificationPermissionStatus()`.
  Future<void> initListeners() async {
    if (_listenersInitialized || platform == null) return;
    _listenersInitialized = true;

    // iOS does not show a banner for a foreground push unless the app
    // opts in via these presentation options (Android has no equivalent
    // switch — onMessage below is what makes foreground display work there).
    if (platform == 'ios') {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp
        .listen((_) => NotificationHandler.instance.openHome());

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      NotificationHandler.instance.openHome();
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    NotificationHandler.instance.showImmediate(
      title: notification.title ?? '',
      body: notification.body ?? '',
    );
  }
}
