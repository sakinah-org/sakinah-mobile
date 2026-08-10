/// Per-prayer notification toggle state (specs/003-prayers-times-screen
/// data-model.md). One instance per prayer (`fajr|dhuhr|asr|maghrib|isha`);
/// five together make up a user's full notification configuration.
class PrayerReminderSetting {
  final String prayerCode;
  final bool isEnabled;
  final int reminderOffsetMinutes;
  final DateTime updatedAt;

  const PrayerReminderSetting({
    required this.prayerCode,
    required this.isEnabled,
    this.reminderOffsetMinutes = 10,
    required this.updatedAt,
  });

  PrayerReminderSetting copyWith({
    bool? isEnabled,
    DateTime? updatedAt,
  }) =>
      PrayerReminderSetting(
        prayerCode: prayerCode,
        isEnabled: isEnabled ?? this.isEnabled,
        reminderOffsetMinutes: reminderOffsetMinutes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Tri-state notification permission (research.md R4) — drives which of
/// FR-012/013/014's Prayers-screen UI states renders.
enum NotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}
