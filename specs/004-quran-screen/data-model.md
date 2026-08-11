# Data Model: Quran Screen

## Entities owned by this feature (`lib/features/quran/`)

### `Surah` (domain entity)

One chapter of the Quran (spec.md Key Entities).

| Field | Type | Notes |
|---|---|---|
| `number` | `int` | 1–114, canonical order; also the sort key and the identifier passed to `getSurah(int)`. |
| `arabicName` | `String` | From `/surah`'s `name` field. |
| `transliteration` | `String` | From `/surah`'s `englishName` field. |
| `meaning` | `String` | English-translated title, from `/surah`'s `englishNameTranslation` field (present on the live API alongside the fields the brief explicitly quoted — research.md R1). |
| `revelationType` | `RevelationType` | Enum `meccan \| medinan`, from `/surah`'s `revelationType` field. |
| `ayahCount` | `int` | From `/surah`'s `numberOfAyahs` field. |

**Validation rules**:
- `number` MUST be in `1..114`, unique across the list.
- `ayahCount` MUST be `> 0`.

### `Ayah` (domain entity)

A single verse (spec.md Key Entities), used only on the Surah Reading screen.

| Field | Type | Notes |
|---|---|---|
| `numberInSurah` | `int` | From `/surah/{n}/quran-uthmani`'s `ayahs[].numberInSurah` — the badge number (FR-010). |
| `text` | `String` | From `ayahs[].text` — Uthmani Arabic script, rendered continuously. |

### `JuzSection` (derived, presentation-facing — not a persisted entity)

Not a standalone stored entity; built by `QuranRepository.getJuz(int)` by grouping a Juz's `ayahs[]` (from `/juz/{n}/quran-uthmani`) by `surah.number`, then resolving each grouped `surah.number` against the already-loaded `Surah` list (research.md R3) to reuse the exact same per-Surah fields the Surah tab shows (spec.md: "content matches the Surah tab data").

| Field | Type | Notes |
|---|---|---|
| `juzNumber` | `int` | 1–30. |
| `surahs` | `List<Surah>` | The Surahs that have at least one ayah in this Juz — full `Surah` entities, not a reduced shape, so the Juz tab's cards show identical fields to the Surah tab (FR-004's parity requirement). |

A `Surah` that spans multiple Juz appears in more than one `JuzSection.surahs` list (spec.md Edge Cases).

### `QuranFontSetting` (domain entity)

The user's Quran text rendering preference (spec.md Key Entities).

| Field | Type | Notes |
|---|---|---|
| `fontFamily` | `String` | One of the 3 available bundled family names (research.md R9). |
| `fontSize` | `double` | Point size applied to `TextStyle.fontSize` for rendered ayat. |

**Default value** (no prior local or remote data — spec.md Edge Cases): `fontFamily = AppTypography.quranFontFamily` ("Lateef", the existing default Quran family), `fontSize` matching the Supabase `user_preferences.quran_font_size` column's own default (`20`), so a guest's local default and an authenticated user's server-side default agree without either side needing to special-case the other.

## Persistence shapes

### Local (Hive, via `SharedPrefHandler`)

Four new keys, following the existing "cache once, reuse" convention (research.md R2):

- `AppPersistenceDataKeys.quranSurahListCache` → JSON array of all 114 `Surah` entities (fetched once, reused forever per R2 — never re-fetched once present, unlike the day-boundary caches elsewhere in this codebase).
- `AppPersistenceDataKeys.quranJuzSectionsCache` → JSON array of all 30 `JuzSection` groupings (surah numbers only — not full `Surah` copies, to avoid duplicating the list cache; resolved against `quranSurahListCache` at read time), fetched once across all 30 Juz calls in parallel (research.md R3).
- `AppPersistenceDataKeys.quranSurahCachePrefix` → per-Surah cache, one Hive entry per fetched Surah's full ayah text, keyed as `'${quranSurahCachePrefix}_$surahNumber'` (e.g. `quran_surah_cache_2`), so opening a previously-read Surah again never re-fetches.
- `AppPersistenceDataKeys.quranFontFamily` / `AppPersistenceDataKeys.quranFontSize` → the two `QuranFontSetting` fields, saved individually (mirrors how `SettingsCubit`'s intended-but-unimplemented persistence and other simple per-value settings are shaped in this codebase — no envelope object needed for two scalars).

If none of the three content caches are present and the corresponding network fetch also fails, the repository falls back to the bundled local asset (research.md R4) rather than throwing.

### Remote

**`public.user_preferences`** (already exists live — verified via schema inspection, not a new migration):

| column | maps to |
|---|---|
| `user_id` | current authenticated user id (`SessionCubit.instance.currentUser?.id`) |
| `quran_font_family` | `QuranFontSetting.fontFamily` |
| `quran_font_size` | `QuranFontSetting.fontSize.round()` (column is `integer`) |

Unique constraint on `user_id` (one row per user) — every write is an `upsert(..., onConflict: 'user_id')`, never a raw `insert`, since other columns on this same row (theme, language, prayer settings — all out of this feature's scope) must not be clobbered by a partial-column upsert; the upsert payload includes only the two Quran columns plus `user_id`.

No remote storage for `Surah`/`Ayah`/`JuzSection` — those are always sourced from the public Quran content API or the bundled local fallback, never written back anywhere.

## State shape (presentation layer)

```
sealed class QuranState                            // QuranCubit — Surah/Juz tabs + search
├── QuranInitialState
├── QuranLoadingState
├── QuranLoadedState
│     { List<Surah> surahs                          // always length 114, canonical order
│     , List<JuzSection> juzSections                // always length 30, once Juz tab has been opened once; empty until then
│     , QuranTab activeTab                          // Surah | Juz
│     , String? searchQuery                         // null when not searching
│     , List<Surah>? searchResults                  // non-null only while searchQuery is active
│     }
└── QuranUnavailableState                           // neither remote nor bundled fallback produced a Surah list (FR-018)

sealed class SurahReadingState                      // SurahReadingCubit — one Surah at a time
├── SurahReadingInitialState
├── SurahReadingLoadingState
├── SurahReadingLoadedState { Surah surah, List<Ayah> ayahs }
└── SurahReadingUnavailableState                     // neither remote nor bundled fallback produced this Surah's text (FR-018)

sealed class QuranFontSettingsState                  // QuranFontSettingsCubit — singleton, cross-screen
└── QuranFontSettingsLoadedState { String fontFamily, double fontSize }
    // Always resolves to a value (falls back to the documented defaults above) —
    // no loading/unavailable state, since this never depends on network.
```

`QuranTab` is a simple `enum { surah, juz }`.

## Relationships to existing entities (unchanged, reused as-is)

- `SessionCubit.instance.currentUser?.id` — gates whether `QuranFontSettingsCubit` also pushes to `user_preferences` (mirrors `PrayerNotificationSettingsCubit`'s existing use of the same gate).
- `AppTypography.quranFontFamily`/`quranLight`/`quranDark` — the existing default font token and base text styles that `QuranFontSetting` overrides `fontFamily`/`fontSize` on top of, not a replacement for them.
