# Data Model: Quran Fonts & Local Data Source Update

This feature does not add, remove, or restructure any domain entity from `specs/004-quran-screen/data-model.md` — `Surah`, `Ayah`, `JuzSection`, and `QuranFontSetting` keep the same fields and types. What changes is (a) where each field is sourced from at the data layer, and (b) `QuranFontSetting`'s available-family list and default. This document only records the delta.

## `Surah` (domain entity — unchanged shape)

| Field | Type | Was sourced from (004) | Now sourced from |
|---|---|---|---|
| `number` | `int` | Al Quran Cloud `/surah`'s `number` | `assets/quran/chapters/index.json` entry's `id` |
| `arabicName` | `String` | `/surah`'s `name` | same entry's `name` |
| `transliteration` | `String` | `/surah`'s `englishName` | same entry's `transliteration` |
| `meaning` | `String` | `/surah`'s `englishNameTranslation` | same entry's `translation` (present because the list file is the **English-locale** variant — research.md R2) |
| `revelationType` | `RevelationType` | `/surah`'s `revelationType` (`"Meccan"`/`"Medinan"`) | same entry's `type` (`"meccan"`/`"medinan"`, lowercase) — existing mapping code already lowercases before comparing, so no logic change needed |
| `ayahCount` | `int` | `/surah`'s `numberOfAyahs` | same entry's `total_verses` |

**Validation rules**: unchanged (`number` in `1..114` and unique; `ayahCount > 0`).

## `Ayah` (domain entity — unchanged shape)

| Field | Type | Was sourced from (004) | Now sourced from |
|---|---|---|---|
| `numberInSurah` | `int` | `/surah/{n}/quran-uthmani`'s `ayahs[].numberInSurah` | `assets/quran/chapters/{n}.json`'s `verses[].id` |
| `text` | `String` | `ayahs[].text` | `verses[].text` |

## `JuzSection` (derived, presentation-facing — unchanged shape, new derivation)

| Field | Type | Notes |
|---|---|---|
| `juzNumber` | `int` | 1–30, unchanged. |
| `surahs` | `List<Surah>` | Unchanged shape (full `Surah` entities). |

**Derivation change**: 004 grouped a Juz's Surahs by reading each ayah's `juz` number (from the live `/juz/{n}` endpoint, or the old bundled asset's `ayahs[].juz` on fallback). Neither is available anymore (research.md R3 — `quran-json` carries no Juz field at all). Instead, `getJuzSections()` now computes membership from the new static `assets/quran/juz_boundaries.json` table (`{juz, startSurah, startAyah}` for all 30 Juz) plus the already-loaded `Surah` list's `ayahCount` per Surah: walking the 114 Surahs in order against the 30 boundary points determines exactly which Surah(s) each Juz spans, and which Surahs cross a boundary (appearing in two consecutive `JuzSection`s) — reproducing the same grouping the ayah-level `juz` field used to give, without needing it.

## `QuranFontSetting` (domain entity — same shape, changed values)

| Field | Type | Notes |
|---|---|---|
| `fontFamily` | `String` | Now one of **4** available bundled family names (was 3). |
| `fontSize` | `double` | Unchanged. |

**`availableFontFamilies`**: `['Amiri', 'Kitab', 'MeQuran', 'QPCHafs']` (research.md R6) — replaces `['Lateef', 'Amiri', 'QPCHafs']`.

**`defaults`**: `fontFamily = 'QPCHafs'` (was `'Lateef'`), `fontSize` unchanged (`20`, still matching `user_preferences.quran_font_size`'s own column default).

**Migration rule** (new — research.md R7): if a loaded `fontFamily` value (local Hive or remote `user_preferences`) is not a member of `availableFontFamilies`, it is treated as unset and replaced with `defaults.fontFamily`, then re-persisted so the correction sticks.

## New: Juz boundary table (bundled static reference data, not a domain entity)

Not exposed as a domain type — read once by `QuranRepositoryImpl` to compute `JuzSection` membership, then discarded (not cached separately; the resulting `JuzSection`s are cached exactly as `quranJuzSectionsCache` already is today).

| Field | Type | Notes |
|---|---|---|
| `juz` | `int` | 1–30. |
| `startSurah` | `int` | Surah number (1–114) this Juz begins in. |
| `startAyah` | `int` | The ayah-within-that-Surah this Juz begins at. |

Source: `assets/quran/juz_boundaries.json`, a hand-authored 30-row table of the standard Uthmani Juz division (research.md R3) — not derived from `risan/quran-json`, which does not carry this data.

## Persistence shapes

### Local (Hive, via `SharedPrefHandler`) — keys unchanged

`AppPersistenceDataKeys.quranSurahListCache`, `quranJuzSectionsCache`, `quranSurahCachePrefix`, `quranFontFamily`, `quranFontSize` — same five keys as 004, same cached shapes. Only how the *first* (cache-miss) value is produced changes (from a network response to a bundled-asset parse); the cache envelope itself is untouched.

### Remote — unchanged

`public.user_preferences`'s `quran_font_family`/`quran_font_size` columns are untouched by this feature (still a free-text column — no `CHECK` constraint exists on the allowed family values, confirmed by there being no migration file in this repo defining one — so widening from 3 to 4 family names requires no schema change).

## State shape (presentation layer) — unchanged

`QuranState`, `SurahReadingState`, and `QuranFontSettingsState` (see `specs/004-quran-screen/data-model.md`) are not modified by this feature — no new state fields, no new state variants. `QuranFontSettingsLoadedState.fontFamily` simply now holds one of 4 possible values instead of 3.
