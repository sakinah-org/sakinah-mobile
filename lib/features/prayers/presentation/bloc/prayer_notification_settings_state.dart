import '../../domain/entities/prayer_reminder_setting.dart';

sealed class PrayerNotificationSettingsState {
  const PrayerNotificationSettingsState();
}

class PrayerNotificationSettingsInitialState
    extends PrayerNotificationSettingsState {
  const PrayerNotificationSettingsInitialState();
}

class PrayerNotificationSettingsLoadingState
    extends PrayerNotificationSettingsState {
  const PrayerNotificationSettingsLoadingState();
}

/// Always reachable — local settings default when nothing is stored, so
/// unlike [PrayerTimesState] this state machine has no error/unavailable
/// member (data-model.md).
class PrayerNotificationSettingsLoadedState
    extends PrayerNotificationSettingsState {
  /// Always length 5, fixed order fajr→isha.
  final List<PrayerReminderSetting> settings;
  final NotificationPermissionStatus permissionStatus;

  const PrayerNotificationSettingsLoadedState(
    this.settings, {
    required this.permissionStatus,
  });

  /// FR-008 — pure derivation, not a stored flag.
  bool get allRemindersOff => settings.every((s) => !s.isEnabled);
}
