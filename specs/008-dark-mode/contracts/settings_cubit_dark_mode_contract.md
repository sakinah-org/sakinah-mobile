# Contract: `SettingsCubit` dark-mode persistence (shared, existing singleton)

`lib/shared/bloc/settings_cubit.dart` — pre-existing global cubit; this feature extends its existing `toggleDarkMode()` and `loadPersistedSettings()` methods. `isDarkMode` field, `setLocale()`, and `toggleLocale()` are unchanged.

## Extended API (signatures unchanged)

```dart
void toggleDarkMode();                       // now persists
Future<void> loadPersistedSettings();         // now also hydrates isDarkMode
```

## `toggleDarkMode()`

Called by `SettingsToggleTile`'s `Switch.onChanged` (`lib/features/settings/presentation/widgets/settings_toggle_tile.dart`) when the user taps the toggle.

1. Flip `isDarkMode = !isDarkMode`.
2. Persist `isDarkMode` to `SharedPrefHandler` under `AppPersistenceDataKeys.isDarkMode`.
3. `emit(LoadedState(isDarkMode))`.

Removes the pre-existing `// TODO: save the value in shared preferences` comment — this is that TODO's resolution.

## `loadPersistedSettings()`

Called once from `main()`, after `SharedPrefHandler.init()` and before `runApp(...)` — same call site that already hydrates `locale`.

1. If `AppPersistenceDataKeys.isDarkMode` is present in `SharedPrefHandler`, set `isDarkMode` to that stored value.
2. Otherwise leave the current default (`false`).
3. Does **not** emit — same reasoning as the existing `locale` hydration: this runs before `runApp`, so there is no listener yet; `MyApp.build()` reads the field directly on first build.

## Consumers (unchanged by this feature)

- `MaterialApp` in `lib/main.dart`: `themeMode: SettingsCubit.instance.isDarkMode ? ThemeMode.dark : ThemeMode.light` — already rebuilds on every `SettingsCubit` emission via the existing `BlocBuilder<SettingsCubit, AppStates>`.

## Out of scope

- Any change to `AppColors`/`lightTheme`/`darkTheme` — already complete (research.md R1).
- System-appearance-follow mode (`ThemeMode.system`) — explicitly out of scope per spec.md Assumptions.
- `setLocale`/`toggleLocale` — untouched by this feature.
