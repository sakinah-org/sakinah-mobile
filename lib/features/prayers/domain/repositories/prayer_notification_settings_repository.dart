import '../entities/prayer_reminder_setting.dart';

/// See specs/003-prayers-times-screen/contracts/supabase_sync_contract.md.
/// Local-first: Hive is the source of truth; Supabase operations are
/// additive/best-effort and only run when the caller passes a signed-in
/// `userId`.
abstract class PrayerNotificationSettingsRepository {
  /// Always returns exactly 5 entries, defaulting every prayer to enabled
  /// when nothing has been stored yet (spec.md Edge Cases).
  Future<List<PrayerReminderSetting>> getLocalSettings();

  /// Persists a single prayer's toggle locally with `updatedAt = now`.
  Future<void> saveLocalSetting(PrayerReminderSetting setting);

  /// Fire-and-forget upsert to Supabase; swallows all failures.
  Future<void> syncToRemote(PrayerReminderSetting setting,
      {required String userId});

  /// Local-first: if this device already has settings saved, they win and
  /// get pushed to Supabase as-is. Only when nothing is saved locally yet
  /// (fresh install / new device) does this adopt Supabase's rows — or
  /// seed Supabase from the defaults if it doesn't have any either.
  Future<List<PrayerReminderSetting>> reconcileWithRemote(
      {required String userId});
}
