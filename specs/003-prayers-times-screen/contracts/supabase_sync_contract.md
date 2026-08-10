# Contract: Supabase sync — `prayer_notification_settings`

`lib/features/prayers/data/repositories/prayer_notification_settings_repository_impl.dart`

Implements the operations specified in this feature's Supabase integration notes, against the already-migrated `public.prayer_notification_settings` table (composite unique `(user_id, prayer_id)`, RLS scoped to `auth.uid()`). **Local-first**: Hive is the source of truth; every operation below is additive/best-effort and only runs when `Supabase.instance.client.auth.currentUser` is non-null.

## 1. Push a single toggle change (called from `PrayerNotificationSettingsCubit.toggle`)

```dart
Future<void> syncToRemote(PrayerReminderSetting setting, {required String userId}) async {
  try {
    await Supabase.instance.client
        .from(AppEndPoints.prayerNotificationSettingsTable)
        .upsert({
          'user_id': userId,
          'prayer_id': _prayerIdFor(setting.prayerCode), // fajr=1..isha=5
          'is_enabled': setting.isEnabled,
          'reminder_offset_minutes': setting.reminderOffsetMinutes,
          'updated_at': setting.updatedAt.toUtc().toIso8601String(),
        }, onConflict: 'user_id,prayer_id');
  } catch (_) {
    // Swallowed per FR-006/spec.md Assumptions — local state already applied;
    // retried on the next successful write or next login pull.
  }
}
```

Called fire-and-forget (not awaited by the UI path) immediately after the local Hive write in `toggle()`.

## 2. Pull + reconcile on login (called from `loadSettings()` when signed in)

```dart
Future<List<PrayerReminderSetting>> reconcileWithRemote({required String userId}) async {
  final local = await getLocalSettings();               // always 5 entries, defaults if none stored
  final rows = await Supabase.instance.client
      .from(AppEndPoints.prayerNotificationSettingsTable)
      .select()
      .eq('user_id', userId);

  if (rows.length < 5) {
    // 3. Seed: fewer than 5 remote rows exist yet — push all 5 current local values in one upsert.
    await Supabase.instance.client
        .from(AppEndPoints.prayerNotificationSettingsTable)
        .upsert(local.map((s) => _toRow(s, userId)).toList(), onConflict: 'user_id,prayer_id');
    return local;
  }

  // Per-prayer last-write-wins: remote row newer → adopt remote value; otherwise keep local
  // (and push local up if it has no newer remote counterpart — same upsert as #1, per-row).
  final merged = <PrayerReminderSetting>[];
  for (final localSetting in local) {
    final remoteRow = rows.firstWhereOrNull(
        (r) => r['prayer_id'] == _prayerIdFor(localSetting.prayerCode));
    final remoteUpdatedAt = remoteRow == null ? null : DateTime.parse(remoteRow['updated_at']);
    if (remoteUpdatedAt != null && remoteUpdatedAt.isAfter(localSetting.updatedAt)) {
      merged.add(PrayerReminderSetting(
        prayerCode: localSetting.prayerCode,
        isEnabled: remoteRow!['is_enabled'] as bool,
        reminderOffsetMinutes: remoteRow['reminder_offset_minutes'] as int,
        updatedAt: remoteUpdatedAt,
      ));
    } else {
      merged.add(localSetting);
      await syncToRemote(localSetting, userId: userId); // push local-newer-or-only value up
    }
  }
  await _persistLocal(merged); // overwrite Hive with the merged, authoritative set
  return merged;
}
```

`reconcileWithRemote` is called once per `loadSettings()` when signed in — not on every screen rebuild — matching the "pull-on-login + push-on-change only, not live multi-device sync" scope from the integration notes (no realtime subscription, no polling).

## Error mapping

`PostgrestException` (and any other exception) from either operation is caught and swallowed at the repository boundary — never surfaced to `PrayerNotificationSettingsCubit` as an error state (this feature's state machine has no error/unavailable member; see data-model.md). No existing `Failure.handlePostgrestException` helper exists in `lib/configurations/app_errors.dart`; none is added since the failure is never shown to the user, only silently retried later.

## Not implemented (explicitly out of scope, per the integration notes)

- No `delete` — rows persist for the account's lifetime; logout does not clear `prayer_notification_settings`.
- No realtime subscription/channel on this table.
