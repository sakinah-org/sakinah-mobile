# Contract: `QuranFontSettingsCubit` (feature singleton)

`lib/features/quran/presentation/bloc/quran_font_settings_cubit.dart`

A singleton (`.instance`, matching `PrayerTimesCubit`/`SessionCubit`/`SettingsCubit`'s existing pattern), but scoped to `lib/features/quran/` rather than promoted to `lib/shared/bloc/` — nothing outside this feature reads it (research.md R5). Provided once, high enough in the widget tree that both `QuranPage` and `SurahReadingPage` see the same live instance (e.g. alongside `SettingsCubit`/`SessionCubit`/`PrayerTimesCubit` in `MyApp`'s `MultiBlocProvider`, or at `MainPage` — either satisfies "provided once, not re-created per screen").

## Access

```dart
BlocProvider.value(
  value: QuranFontSettingsCubit.instance,
  child: ...,
)
```

## Public API

```dart
Future<void> load();
// Reads QuranRepository.getFontSetting() (local Hive, always resolves —
// see data-model.md defaults) and emits it immediately. If
// SessionCubit.instance.currentUser?.id is non-null, additionally calls
// QuranRepository.fetchRemoteFontSetting(userId) in the background; if it
// returns a non-null value, that becomes the new emitted state (remote
// wins on first load for an authenticated user — this is the one point
// where remote can override local, since after this the two are kept in
// sync going forward by setFontFamily/setFontSize below, mirroring how
// SC-006/spec.md Edge Cases describe cross-device propagation).

void setFontFamily(String fontFamily);
void setFontSize(double fontSize);
// Both: update in-memory state immediately (FR-014 — no sheet-close
// required), then call QuranRepository.saveFontSetting(...) with the
// full updated {fontFamily, fontSize} pair and the current
// SessionCubit.instance.currentUser?.id (fire-and-forget remote sync per
// quran_repository_contract.md).
```

## States emitted

Single-member state (see data-model.md): `QuranFontSettingsLoadedState { fontFamily, fontSize }`. There is no loading/unavailable state — `load()` always has a value to emit immediately from local defaults even before any remote check completes, so consumers never need to special-case "not yet known."

## Consumers

- `QuranFontSettingsSheet` widget (opened from either screen's app bar per FR-012) — reads current state to show the selected size/family and live previews, calls `setFontFamily`/`setFontSize` on interaction.
- `SurahReadingView` — reads current state to style rendered ayat (FR-011).
- Any live-preview sample text inside the sheet itself (FR-013) reads the *candidate* value being previewed, not this Cubit's committed state, until the user actually selects it.
