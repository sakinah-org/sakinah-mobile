# Contract: `PrayerNotificationSettingsCubit` (feature-scoped)

`lib/features/prayers/presentation/bloc/prayer_notification_settings_cubit.dart`

Unlike `PrayerTimesCubit`, this is **not** a global singleton — it is provided via `BlocProvider` scoped to `PrayersPage` only, since notification-toggle UI state has no other consumer today. It composes with, but never replaces, `PrayerTimesCubit.instance` (still the sole source of prayer times/location on this screen).

## Access

```dart
BlocProvider(
  create: (_) => PrayerNotificationSettingsCubit(repository: PrayerNotificationSettingsRepositoryImpl())
    ..loadSettings(),
  child: const PrayersView(),
)
```

## Public API

```dart
Future<void> loadSettings();
// Reads local Hive settings (defaulting all five to enabled if none stored — see data-model.md),
// checks current NotificationPermissionStatus, reconciles with Supabase if signed in
// (see supabase_sync_contract.md), reschedules local reminders for all enabled prayers
// against the current PrayerTimesCubit.instance times, and emits Loaded.

Future<void> toggle(String prayerCode, bool isEnabled);
// Optimistically emits the updated Loaded state immediately (FR-002 acceptance scenario 2/3),
// persists to Hive with updatedAt = now, schedules/cancels that prayer's local reminder,
// and — fire-and-forget, if signed in — upserts to Supabase (see supabase_sync_contract.md).
// A failed Supabase write does not re-emit an error state or roll back the local toggle.

Future<void> requestNotificationPermission();
// Triggers the OS permission prompt (FR-012, first visit only). Re-checks status afterward
// and re-emits Loaded with the updated permissionStatus. No-op if status is already
// granted/permanentlyDenied (permanently-denied requires openNotificationSettings() instead).

Future<void> openNotificationSettings();
// Opens the device's app notification settings (permission_handler's openAppSettings()),
// for the "Enable" control on the denied/permanently-denied help cards (FR-013/014).
// Does not itself re-check permission — the screen re-checks on next resume/loadSettings().
```

## States emitted (see data-model.md for field shapes)

| State | When | Consumers do |
|---|---|---|
| `PrayerNotificationSettingsInitialState` | Before first `loadSettings()` call | Show a loading skeleton for the prayer list. |
| `PrayerNotificationSettingsLoadingState` | `loadSettings()` in flight | Keep skeleton / keep last-known list visible if re-loading. |
| `PrayerNotificationSettingsLoadedState(settings, permissionStatus)` | Settings resolved (always reachable — no unavailable state, local-first) | Render five `PrayerReminderTile`s from `settings`; render the all-off banner when every `settings[i].isEnabled == false`; render the permission help/permanently-denied card and toggle-disabled styling based on `permissionStatus`. |

## Relationship to `PrayerTimesCubit`

`PrayerNotificationSettingsCubit` reads `PrayerTimesCubit.instance.state` to get each prayer's time-of-day (for display, and to compute each reminder's fire time as `time − 10 minutes` when scheduling) — it does not hold or duplicate prayer-time data itself, and does not call `PrayerTimesRepository` directly (per `prayer_times_cubit_contract.md`'s constraint). If `PrayerTimesCubit` has no loaded times yet (e.g. `PrayerTimesLocationRequiredState`), reminder scheduling is simply skipped for that load — toggles still work and persist, they just have nothing to schedule against until times become available.

## Permission re-check on resume

The Prayers screen re-runs the permission-status portion of `loadSettings()` (not a full reconcile) on `didChangeAppLifecycleState` resume, so that returning from the device's notification settings (after `openNotificationSettings()`) reflects the new status without requiring the user to fully leave and reopen the screen — satisfies FR-013's "toggles work normally once permission is granted and the user returns to the screen."
