# Contract: `SettingsCubit` extensions (shared, existing singleton)

`lib/shared/bloc/settings_cubit.dart` — pre-existing global cubit; this feature adds the methods below. Existing `toggleDarkMode()`/`toggleLocale()` and the `isDarkMode`/`locale` fields are unchanged.

## New public API

```dart
Future<void> setLocale(Locale locale);      // explicit selection — locale must be Locale('ar') or Locale('en')
Future<void> loadPersistedSettings();        // startup hydration; call once, before runApp
```

## `setLocale(Locale locale)`

Called by the language bottom sheet (`lib/features/settings/presentation/widgets/`) when the user taps a row.

1. If `locale == this.locale`, still persist/emit (idempotent) — sheet simply closes with no visible change (spec.md US3 scenario 4).
2. Set `this.locale = locale`.
3. Persist `locale.languageCode` to `SharedPrefHandler` under `AppPersistenceDataKeys.appLocale`.
4. `emit(LoadedState(locale))`.

Consumers: `MaterialApp` in `lib/main.dart` already rebuilds on any `SettingsCubit` emission and reads `SettingsCubit.instance.locale` — no consumer-side change needed there.

## `loadPersistedSettings()`

Called once from `main()`, after `SharedPrefHandler.init()` and before `runApp(...)`, alongside the existing `QuranFontSettingsCubit.instance.load()` call.

1. If `AppPersistenceDataKeys.appLocale` is present in `SharedPrefHandler`, set `locale` to that value (`Locale(storedCode)`).
2. Otherwise leave the current default (`Locale('ar')`).
3. Does **not** emit if nothing changed — this runs before `runApp`, so there is no listener yet; the value is simply read by `MyApp.build()` on first build.

## Out of scope

- Dark mode persistence (`toggleDarkMode`) — untouched by this feature; pre-existing `// TODO` is not resolved here.
- Any remote/Supabase sync of the language preference — per spec.md Assumptions, out of scope for this feature.
