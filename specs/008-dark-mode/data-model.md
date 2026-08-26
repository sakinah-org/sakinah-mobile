# Phase 1 Data Model: Dark Mode

No new persisted entity/table/collection is introduced — this feature adds one field to the existing, already-persisted `SettingsCubit` state and one Hive key. Documented here as the spec's Key Entity, in implementation terms.

## Theme Preference

Owned by `SettingsCubit` (`lib/shared/bloc/settings_cubit.dart`), alongside the existing `locale` field it already persists the same way.

| Field | Type | Notes |
|---|---|---|
| `isDarkMode` | `bool` | Already exists on `SettingsCubit` as an in-memory field, default `false`. This feature adds persistence: written on every `toggleDarkMode()` call, read back in `loadPersistedSettings()`. |

**Persistence**: `AppPersistenceDataKeys.isDarkMode` (new key, `'is_dark_mode'`), stored via `SharedPrefHandler.instance!.save(key, value: bool)` and read via `SharedPrefHandler.instance!.get<bool>(key: ...)`, guarded by `SharedPrefHandler.instance!.contains(key)` on hydration — same triad `setLocale`/`loadPersistedSettings` already use for `appLocale`.

**State transitions**:

```
[no persisted value] --loadPersistedSettings()--> isDarkMode = false (default, unchanged)
[persisted value exists] --loadPersistedSettings()--> isDarkMode = <persisted value>
[any value] --toggleDarkMode()--> isDarkMode = !isDarkMode --> persist --> emit(LoadedState(isDarkMode))
```

**Validation rules**: None beyond the type itself — a `bool` has no invalid states. This differs from `locale`, which validates against two supported `Locale` values; a theme toggle only ever flips between exactly two states with no invalid third option.

**Consumers**: `MaterialApp` in `lib/main.dart` (`themeMode: SettingsCubit.instance.isDarkMode ? ThemeMode.dark : ThemeMode.light` — already wired, unchanged by this feature) and the new `SettingsToggleTile` widget (reads `context.watch<SettingsCubit>().isDarkMode` for the `Switch` value, calls `SettingsCubit.instance.toggleDarkMode()` on change).

No relationships to other entities — this is a single, independent boolean preference, same shape as `Locale` but simpler (2 fixed states vs. a value type).
