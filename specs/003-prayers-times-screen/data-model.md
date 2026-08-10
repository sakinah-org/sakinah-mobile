# Data Model: Prayers Times Screen

## Entities owned by this feature (`lib/features/prayers/`)

### `PrayerReminderSetting` (domain entity)

Per-prayer notification toggle state, for one of the five fixed prayers.

| Field | Type | Notes |
|---|---|---|
| `prayerCode` | `String` | One of `fajr\|dhuhr\|asr\|maghrib\|isha` — reuses the same code convention as `lib/shared/prayer_times/domain/entities/prayer_times.dart`'s `NextPrayer.code` and `prayer_code_presentation.dart`. |
| `isEnabled` | `bool` | Whether a reminder is scheduled for this prayer. |
| `reminderOffsetMinutes` | `int` | Fixed `10` for all users in v1 (spec.md Assumptions). Carried as a field (not a hardcoded literal at every call site) so it round-trips cleanly through the Supabase row shape. |
| `updatedAt` | `DateTime` | Local device timestamp of the last change to `isEnabled` for this prayer. Drives last-write-wins reconciliation against the remote row's `updated_at` (FR-007). |

Five instances of this entity — one per prayer, always present (defaulted, never null/missing) — make up a user's full notification configuration.

**Validation rules**:
- `prayerCode` MUST be one of the five fixed codes; no arbitrary values.
- `reminderOffsetMinutes` is always `10` in v1 — not user-editable, included for forward compatibility with the Supabase schema's `reminder_offset_minutes` column.
- `updatedAt` is set to "now" (device clock) every time `isEnabled` changes locally — never backdated.

**Default value** (no prior local or remote data — spec.md Edge Cases): all five prayers, `isEnabled: true`, `updatedAt` = first-load time.

### `NotificationPermissionStatus` (enum)

`notDetermined | granted | denied | permanentlyDenied` — mirrors the tri-state `permission_handler` exposes (see research.md R4), used to select which of FR-012/013/014's UI states to render.

## Persistence shapes

### Local (Hive, via `SharedPrefHandler`)

New key: `AppPersistenceDataKeys.prayerNotificationSettings` → JSON-encoded envelope (same pattern as `CachedPrayerTimes` in `lib/shared/prayer_times/data/models/prayer_times_model.dart`):

```json
{
  "fajr":    { "isEnabled": true,  "updatedAt": "2026-08-09T03:12:00.000Z" },
  "dhuhr":   { "isEnabled": true,  "updatedAt": "2026-08-09T03:12:00.000Z" },
  "asr":     { "isEnabled": false, "updatedAt": "2026-08-10T14:05:22.000Z" },
  "maghrib": { "isEnabled": true,  "updatedAt": "2026-08-09T03:12:00.000Z" },
  "isha":    { "isEnabled": true,  "updatedAt": "2026-08-09T03:12:00.000Z" }
}
```

`reminderOffsetMinutes` is not persisted per-entry locally (it's a fixed `10` constant applied when constructing `PrayerReminderSetting` in memory) — only `isEnabled`/`updatedAt` vary.

### Remote (`public.prayer_notification_settings`, already migrated — see Supabase schema)

| column | maps to |
|---|---|
| `user_id` | current authenticated user id (`Supabase.instance.client.auth.currentUser?.id`) |
| `prayer_id` | looked up from `prayerCode` via the fixed 1–5 mapping (`fajr=1, dhuhr=2, asr=3, maghrib=4, isha=5`) matching `public.prayers.sort_order`/`code` |
| `is_enabled` | `PrayerReminderSetting.isEnabled` |
| `reminder_offset_minutes` | `PrayerReminderSetting.reminderOffsetMinutes` (always `10`) |
| `updated_at` | `PrayerReminderSetting.updatedAt`, UTC ISO-8601 |

Composite unique constraint `(user_id, prayer_id)` — every write is an `upsert` (never `insert`), matching the integration notes supplied for this feature.

## Derived / display-only concepts (not persisted by this feature)

- **Resolved location label** (`{city, country}`): produced by `PrayerTimesRepository.resolveDisplayLocation()` (research.md R1), owned by `lib/shared/prayer_times/`, cached alongside the existing lat/lng entry — not duplicated in this feature's storage.
- **Hijri date**: computed on the fly via the existing `now.hijriDateLabel(locale)` extension (`lib/toolkit/extensions/date_time_extensions.dart`), same as `HomeGreetingHeader` — no new storage.
- **All-off banner visibility**: a pure function of the five `PrayerReminderSetting.isEnabled` values in the current `Loaded` state (`settings.every((s) => !s.isEnabled)`) — not a stored flag.

## State shape (presentation layer)

```
sealed class PrayerNotificationSettingsState
├── PrayerNotificationSettingsInitialState
├── PrayerNotificationSettingsLoadingState
└── PrayerNotificationSettingsLoadedState
      { List<PrayerReminderSetting> settings   // always length 5, fixed order fajr→isha
      , NotificationPermissionStatus permissionStatus
      }
```

No error/unavailable state: local settings always resolve to a value (defaults if nothing stored), so this state machine only has three members — unlike `PrayerTimesState`, which has network-dependent unavailable/fallback states.

## Relationships to existing entities (unchanged, reused as-is)

- `PrayerTimes` (`lib/shared/prayer_times/domain/entities/prayer_times.dart`) — supplies each prayer's time-of-day; this feature reads it via `PrayerTimesCubit.instance`, never refetches independently.
- `PrayerLocation` / `Coordinates` / `City` — supplies the location this screen displays; unchanged except for the new `resolveDisplayLocation()` addition (research.md R1).
- `CalculationMethod` — supplies the calculation-method label on the location card; read via `PrayerTimesRepository.getStoredCalculationMethod()` (existing method, unchanged).
