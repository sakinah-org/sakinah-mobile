# Contract: `NotificationHandler` (device notification scheduling)

`lib/handlers/notification_handler.dart` — new handler, singleton (`NotificationHandler.instance`), same shape as `ImagePickerHandler`/`LocationHandler`: a plain class doing stateful device interaction, not a Cubit and not a widget. Wraps `flutter_local_notifications` + `timezone` (research.md R3). Permission status/requests are **not** this handler's job — that stays on `PermissionHandler.checkNotificationPermissionStatus()` (research.md R4); this handler only schedules/cancels/presents, assuming permission has already been checked by the caller.

## Public API

```dart
Future<void> init();
// One-time setup: initializes the plugin with platform-specific settings, initializes the
// `timezone` package with the device's local IANA zone, and configures Darwin (iOS)
// presentation options (alert/sound while foregrounded) so foreground and background
// delivery both go through this same scheduled-notification path (research.md R3 — no
// separate custom in-app banner system). Called once at app startup (main.dart), alongside
// the existing Supabase.initialize/SharedPrefHandler.init sequence.

Future<void> scheduleReminder({
  required String prayerCode,      // fajr|dhuhr|asr|maghrib|isha
  required DateTime prayerTime,    // that prayer's time today
});
// Computes fireAt = prayerTime.subtract(Duration(minutes: 10)) and calls zonedSchedule with a
// deterministic notification id derived from prayerCode (fajr=1 .. isha=5), so re-scheduling
// the same prayer is idempotent (replaces any existing scheduled notification for that id,
// never duplicates). No-op (does not schedule) if fireAt is already in the past for today.

Future<void> cancelReminder({required String prayerCode});
// Cancels the pending scheduled notification for that prayer's deterministic id, if any.

Future<void> rescheduleAll(List<PrayerReminderSetting> settings, PrayerTimes times);
// Cancels all five deterministic ids, then calls scheduleReminder for each setting where
// isEnabled == true, using that prayer's time from `times`. Called from
// PrayerNotificationSettingsCubit.loadSettings() on every screen load/app resume — this is
// the mechanism that covers FR-017's "request permission again / retry on next app launch"
// and mitigates scheduled alarms not surviving a device reboot (research.md R3).
```

## Tap-to-open behavior (FR-016)

The plugin's notification-tap callback (registered in `init()`) navigates to `AppRoutes.home` via the existing `Navigator`/`onGenerateRoute` mechanism (`lib/navigation/route_generator.dart`) — no new routing mechanism, no route arguments needed since the destination is always Home.

## Delivery-failure handling (FR-017)

If the OS rejects delivery because permission was revoked after scheduling, `flutter_local_notifications` fails at the OS level, not inside this app's code — there is nothing for `NotificationHandler` to catch. The user-facing side of FR-017 ("no error shown, retry permission on next launch") is satisfied structurally: `rescheduleAll()` runs again on next `loadSettings()`, and if `PermissionHandler.checkNotificationPermissionStatus()` reports non-granted at that point, `PrayerNotificationSettingsCubit` surfaces the denied/permanently-denied card (FR-013/014) rather than any error — there is no separate failure path to construct.

## What this handler does not do

- Does not request or check permission (see `PermissionHandler`).
- Does not implement Firebase/FCM push (research.md R3 — out of scope for v1).
- Does not persist which prayers are enabled — it is called with that data by `PrayerNotificationSettingsCubit`, which owns it (data-model.md).
