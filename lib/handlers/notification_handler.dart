import 'dart:developer';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../navigation/app_routes.dart';

/// Wraps `flutter_local_notifications` + `timezone` for prayer-reminder
/// scheduling (specs/003-prayers-times-screen). Same shape as
/// `LocationHandler`/`ImagePickerHandler`: a plain singleton doing device
/// interaction, not a Cubit. Does NOT request/check permission — that stays
/// on `PermissionHandler.checkNotificationPermissionStatus()`.
/// See contracts/notification_scheduling_contract.md.
class NotificationHandler {
  NotificationHandler._internal();
  static final NotificationHandler instance = NotificationHandler._internal();

  /// Exposed so `main.dart`'s `MaterialApp` can wire it up, giving the
  /// notification-tap callback a way to navigate without a `BuildContext`.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'Prayer Reminders';

  /// Deterministic per-prayer id (fajr=1..isha=5), kept local to this
  /// handler rather than importing the `prayers` feature's own mapping —
  /// `lib/handlers/` must not depend on `lib/features/` (Constitution
  /// Principle I).
  static const Map<String, int> _notificationIds = {
    'fajr': 1,
    'dhuhr': 2,
    'asr': 3,
    'maghrib': 4,
    'isha': 5,
  };

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permission requesting stays on PermissionHandler — don't let the
    // plugin's own init prompt the OS dialog a second time on iOS.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => openHome(),
    );

    // Created eagerly (rather than relying on the first zonedSchedule() call
    // to lazily create it) so an FCM push referencing this channel id via
    // the Android manifest's default_notification_channel_id meta-data
    // always has somewhere to land, even before any prayer reminder has
    // ever been scheduled on this device.
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(_channelId, _channelName),
          );
    }
    _initialized = true;
  }

  /// Navigates to the main route, discarding the back stack. Used both for
  /// local-notification taps (above) and for FCM notification taps
  /// (`FcmHandler`) — same "just land on Home" behavior either way.
  void openHome() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.main,
      (route) => false,
    );
  }

  /// Displays a push notification immediately, for FCM messages that arrive
  /// while the app is in the foreground (where the OS does not auto-display
  /// them — see `FcmHandler.initListeners`). Reuses the same channel as
  /// scheduled prayer reminders.
  Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
        ),
      ),
    );
  }

  /// Android 12+ gates [AndroidScheduleMode.exactAllowWhileIdle] behind the
  /// user-grantable `SCHEDULE_EXACT_ALARM` permission (auto-denied by
  /// default on Android 14+). Requests it once, and falls back to an
  /// inexact schedule mode rather than letting `zonedSchedule` throw
  /// `exact_alarms_not_permitted`.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return AndroidScheduleMode.exactAllowWhileIdle;

    var canScheduleExact =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    if (!canScheduleExact) {
      canScheduleExact =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
    }
    return canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> scheduleReminder({
    required String prayerCode,
    required DateTime prayerTime,
  }) async {
    final id = _notificationIds[prayerCode];
    if (id == null) return;

    final fireAt = prayerTime.subtract(const Duration(minutes: 10));
    if (fireAt.isBefore(DateTime.now())) return; // FR-005: today only

    // Scheduled as an absolute UTC instant rather than resolving the
    // device's local IANA zone — this handler always reschedules fresh
    // (rescheduleAll, called on every load) rather than relying on
    // recurring local-time matching, so a fixed-offset UTC TZDateTime
    // represents the intended moment correctly without an extra
    // device-timezone-name dependency.
    final scheduled = tz.TZDateTime.from(fireAt.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      id: id,
      title: 'Prayer Reminder',
      body: '10 minutes until $prayerCode',
      scheduledDate: scheduled,
      androidScheduleMode: await _resolveAndroidScheduleMode(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
        ),
      ),
    );
  }

  Future<void> cancelReminder({required String prayerCode}) async {
    final id = _notificationIds[prayerCode];
    if (id == null) return;
    await _plugin.cancel(id: id);
  }

  Future<void> rescheduleAll(
    List<({String prayerCode, bool isEnabled})> settings,
    Map<String, DateTime> timesByPrayerCode,
  ) async {
    for (final id in _notificationIds.values) {
      await _plugin.cancel(id: id);
    }
    for (final setting in settings) {
      final time = timesByPrayerCode[setting.prayerCode];
      if (setting.isEnabled && time != null) {
        await scheduleReminder(
          prayerCode: setting.prayerCode,
          prayerTime: time,
        );
      }
    }
    log('NotificationHandler.rescheduleAll: rescheduled '
        '${settings.where((s) => s.isEnabled).length} reminder(s)');
  }
}
