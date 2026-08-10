import '../../domain/entities/prayer_reminder_setting.dart';

/// Hive envelope (de)serialization + Supabase row mapping for
/// [PrayerReminderSetting] — specs/003-prayers-times-screen/data-model.md.
class PrayerNotificationSettingModel {
  static const List<String> prayerCodes = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Fixed 1–5 mapping matching `public.prayers.sort_order`.
  static const Map<String, int> _prayerIds = {
    'fajr': 1,
    'dhuhr': 2,
    'asr': 3,
    'maghrib': 4,
    'isha': 5,
  };

  static int prayerIdFor(String code) => _prayerIds[code]!;

  static String codeForPrayerId(int id) =>
      _prayerIds.entries.firstWhere((e) => e.value == id).key;

  /// `{fajr: {isEnabled, updatedAt}, ...}` — missing entries default to
  /// enabled=true at "now" (spec.md Edge Cases: first-ever load).
  static List<PrayerReminderSetting> defaults() {
    final now = DateTime.now();
    return prayerCodes
        .map((code) => PrayerReminderSetting(
              prayerCode: code,
              isEnabled: true,
              updatedAt: now,
            ))
        .toList();
  }

  static Map<String, dynamic> toHiveJson(List<PrayerReminderSetting> settings) {
    return {
      for (final setting in settings)
        setting.prayerCode: {
          'isEnabled': setting.isEnabled,
          'updatedAt': setting.updatedAt.toIso8601String(),
        },
    };
  }

  static List<PrayerReminderSetting> fromHiveJson(Map raw) {
    final now = DateTime.now();
    return prayerCodes.map((code) {
      final entry = raw[code];
      if (entry is! Map) {
        return PrayerReminderSetting(
            prayerCode: code, isEnabled: true, updatedAt: now);
      }
      return PrayerReminderSetting(
        prayerCode: code,
        isEnabled: entry['isEnabled'] as bool,
        updatedAt: DateTime.parse(entry['updatedAt'] as String),
      );
    }).toList();
  }

  static Map<String, dynamic> toSupabaseRow(
    PrayerReminderSetting setting, {
    required String userId,
  }) {

    return {
      'user_id': userId,
      'prayer_id': prayerIdFor(setting.prayerCode),
      'is_enabled': setting.isEnabled,
      'reminder_offset_minutes': setting.reminderOffsetMinutes,
      'updated_at': setting.updatedAt.toUtc().toIso8601String(),
    };
  }

  static PrayerReminderSetting fromSupabaseRow(Map<String, dynamic> row) {
    return PrayerReminderSetting(
      prayerCode: codeForPrayerId(row['prayer_id'] as int),
      isEnabled: row['is_enabled'] as bool,
      reminderOffsetMinutes: (row['reminder_offset_minutes'] as int?) ?? 10,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
