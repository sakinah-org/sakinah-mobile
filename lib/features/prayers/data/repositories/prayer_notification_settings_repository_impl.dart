import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../configurations/app_end_points.dart';
import '../../../../configurations/app_persistence_data_keys.dart';
import '../../../../handlers/shared_handler.dart';
import '../../domain/entities/prayer_reminder_setting.dart';
import '../../domain/repositories/prayer_notification_settings_repository.dart';
import '../models/prayer_notification_setting_model.dart';

/// See specs/003-prayers-times-screen/contracts/supabase_sync_contract.md.
class PrayerNotificationSettingsRepositoryImpl
    implements PrayerNotificationSettingsRepository {
  PrayerNotificationSettingsRepositoryImpl({SharedPrefHandler? prefs})
      : _prefs = prefs ?? SharedPrefHandler.instance!;

  final SharedPrefHandler _prefs;

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  @override
  Future<List<PrayerReminderSetting>> getLocalSettings() async {
    if (!_prefs.contains(AppPersistenceDataKeys.prayerNotificationSettings)) {
      return PrayerNotificationSettingModel.defaults();
    }
    try {
      final raw = _prefs.get<Map>(
          key: AppPersistenceDataKeys.prayerNotificationSettings);
      return PrayerNotificationSettingModel.fromHiveJson(raw);
    } catch (_) {
      return PrayerNotificationSettingModel.defaults();
    }
  }

  @override
  Future<void> saveLocalSetting(PrayerReminderSetting setting) async {
    final current = await getLocalSettings();
    final updated = [
      for (final existing in current)
        existing.prayerCode == setting.prayerCode ? setting : existing,
    ];
    await _persistLocal(updated);
  }

  Future<void> _persistLocal(List<PrayerReminderSetting> settings) async {
    await _prefs.save(
      AppPersistenceDataKeys.prayerNotificationSettings,
      value: PrayerNotificationSettingModel.toHiveJson(settings),
    );
  }

  @override
  Future<void> syncToRemote(
    PrayerReminderSetting setting, {
    required String userId,
  }) async {
    try {
      await _client.from(AppEndPoints.prayerNotificationSettingsTable).upsert(
            PrayerNotificationSettingModel.toSupabaseRow(setting,
                userId: userId),
            onConflict: 'user_id,prayer_id',
          );
    } catch (e) {
      // Swallowed per FR-006/spec.md Assumptions — local state already
      // applied; retried on the next successful write or next login pull.
      log('PrayerNotificationSettingsRepositoryImpl.syncToRemote failed: $e');
    }
  }

  @override
  Future<List<PrayerReminderSetting>> reconcileWithRemote({
    required String userId,
  }) async {
    final local = await getLocalSettings();
    final hasLocalData =
        _prefs.contains(AppPersistenceDataKeys.prayerNotificationSettings);

    // This device already has its own settings — per this repository's
    // local-first contract, local always wins. Just push it up so a
    // *different* device signing in later sees the latest values.
    if (hasLocalData) {
      await _pushAllToRemote(local, userId: userId);
      return local;
    }

    // Fresh install / new device with nothing saved locally yet: adopt
    // whatever's already on Supabase, or seed it from the defaults.
    try {
      final rows = await _client
          .from(AppEndPoints.prayerNotificationSettingsTable)
          .select()
          .eq('user_id', userId);

      if (rows.length < 5) {
        await _pushAllToRemote(local, userId: userId);
        return local;
      }

      final remote = [
        for (final row in rows)
          PrayerNotificationSettingModel.fromSupabaseRow(row),
      ];
      await _persistLocal(remote);
      return remote;
    } catch (e) {
      log('PrayerNotificationSettingsRepositoryImpl.reconcileWithRemote failed: $e');
      return local;
    }
  }

  Future<void> _pushAllToRemote(
    List<PrayerReminderSetting> settings, {
    required String userId,
  }) async {
    try {
      await _client.from(AppEndPoints.prayerNotificationSettingsTable).upsert(
            settings
                .map((s) => PrayerNotificationSettingModel.toSupabaseRow(s,
                    userId: userId))
                .toList(),
            onConflict: 'user_id,prayer_id',
          );
    } catch (e) {
      log('PrayerNotificationSettingsRepositoryImpl._pushAllToRemote failed: $e');
    }
  }
}
