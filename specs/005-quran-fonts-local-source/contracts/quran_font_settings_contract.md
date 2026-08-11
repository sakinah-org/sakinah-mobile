# Contract: `QuranFontSettingsCubit` (updated note)

`lib/features/quran/presentation/bloc/quran_font_settings_cubit.dart` — public API is **unchanged** from `specs/004-quran-screen/contracts/quran_font_settings_contract.md` (`load()`, `setFontFamily(String)`, `setFontSize(double)`, single `QuranFontSettingsLoadedState { fontFamily, fontSize }`). This file only records what's different in this update.

## What changes

- `load()`'s underlying `QuranRepository.getFontSetting()` call now returns one of **4** possible `fontFamily` values (`Amiri`, `Kitab`, `MeQuran`, `QPCHafs` — research.md R6) instead of 3, and may itself perform the stale-value migration described in `quran_repository_contract.md` (research.md R7) before the Cubit ever sees the value — the Cubit does not need its own migration logic; it always receives an already-valid family name.
- Nothing about `setFontFamily`/`setFontSize`'s contract changes — they still accept any `String`/`double` and persist immediately; validating that a caller only ever passes one of the 4 `availableFontFamilies` values is the UI's responsibility (the font-settings sheet only ever offers those 4 as selectable options), the same way it was the UI's responsibility to only offer 3 before.

## Consumers (unchanged)

- `QuranFontSettingsSheet` — now renders 4 live-preview cards instead of 3 (its family iteration is already dynamic over `QuranFontSetting.availableFontFamilies`, per research.md R8 — only its per-family label text needs an implementation-time look, not its structure).
- `SurahReadingView` — unaffected; still just applies whatever `fontFamily`/`fontSize` the state currently holds.
