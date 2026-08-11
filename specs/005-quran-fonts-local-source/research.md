# Research: Quran Fonts & Local Data Source Update

Phase 0 output. Each decision resolves a gap between spec.md's requirements and what already exists in the codebase (per inspection of `lib/features/quran/`, `pubspec.yaml`, `assets/quran/quran_uthmani.json`, and the live contents of `github.com/risan/quran-json` at `dist/chapters/index.json`, `dist/chapters/en/index.json`, `dist/chapters/{n}.json`, `dist/chapters/en/{n}.json`, and `dist/verses/`).

## R1. Data source scope — confirmed local-only (Clarifications session 2026-08-11)

**Decision**: `QuranRepositoryImpl`'s `getSurahList()`, `getJuzSections()`, and `getSurah(int)` stop calling `DioClient`/`AppEndPoints.quranCloud*` entirely. All three are backed only by data bundled in the app; there is no remote fetch and no "remote-first, local-fallback" branch left in these three methods.

**Rationale**: Directly matches the confirmed spec.md clarification and FR-005. Removing the network branch (rather than keeping it dead-code-present) avoids the `DioException` handling paths that no longer have a caller.

**Alternatives considered**: Keep remote as primary, swap only the offline-fallback dataset — rejected per the user's explicit answer during specification.

## R2. Source files from `risan/quran-json` — the list file must be the English-locale variant, not the bare index

**Decision**: Use two different files from the repo depending on what's needed:

- **Combined Surah list** (`getSurahList()`): `dist/chapters/en/index.json`, **not** the bare `dist/chapters/index.json` the feature brief pointed at. Verified shape of the bare file: `{id, name, transliteration, type, total_verses, link}` — no English meaning/title field. Verified shape of the `en/` variant: identical, plus `translation` (e.g. `"The Opener"` for Surah 1) — this is the only file in the repo that carries the field `Surah.meaning` (spec.md FR-002, unchanged) needs.
- **Per-Surah ayah text** (`getSurah(int)`): `dist/chapters/{n}.json` (the plain, non-English-locale file — exactly as the brief pointed at), shape `{id, name, transliteration, type, total_verses, verses: [{id, text, transliteration}]}`. The per-verse `transliteration` field is present but unused (spec.md's Ayah entity only needs Arabic `text` + its number).

**Rationale**: Silently using the bare `chapters/index.json` would drop the `meaning` field that FR-002/FR-008 (unchanged from spec 004) still requires every Surah entry to show — the `en/` variant is a one-file substitution that preserves that requirement without deviating from the rest of the brief's intent (still "one list file for both Surah and Juz views," still sourced from the same repo).

**Alternatives considered**: Source `meaning` from a third file (`dist/quran_en.json`, which also carries `translation` per-chapter) — rejected as an unnecessary extra file when `chapters/en/index.json` already covers it in the one list file the brief asked for.

## R3. Juz boundaries — not present anywhere in `quran-json`; needs one small supplementary bundled table

**Decision**: Verified that no file in `risan/quran-json` (`dist/chapters/index.json`, `dist/chapters/en/index.json`, `dist/chapters/{n}.json`, `dist/verses/{n}.json`) carries a per-ayah or per-Surah Juz number, unlike the current bundled `assets/quran/quran_uthmani.json` (which has `ayahs[].juz`, sourced from Al Quran Cloud). Since FR-004 (unchanged) still requires the Juz view to group Surahs under Juz headers 1–30, this plan adds one small additional bundled local asset — `assets/quran/juz_boundaries.json` — a static 30-entry table of `{juz, startSurah, startAyah}` marking where each Juz begins (the fixed, universally standard Uthmani Juz division; the same boundaries Al Quran Cloud's own `/juz/{n}` endpoints already reflect, and every Quran app uses). Combined with each Surah's `total_verses` (already in `chapters/en/index.json`), `QuranRepositoryImpl` computes which Surah(s) fall under each Juz the same way the old bundled asset let it group by `ayahs[].juz`, without needing that field.

**Rationale**: The alternative — dropping Juz grouping — would silently break an unchanged, still-required part of the feature (FR-004, User Story 3 of spec 004). A 30-row static boundary table is small, standard, unchanging reference data, not scripture text itself, so it carries none of 004 research R4's "must come from a verified scripture source" concern — it's a well-known structural fact about the Mushaf, not translatable/interpretable content.

**Alternatives considered**: Keep calling the remote `/juz/{n}` endpoints just for Juz grouping while everything else goes local — rejected, contradicts R1's confirmed local-only decision (a partial network dependency would still require network-error handling, connectivity checks, and would violate FR-005 as written). Deriving boundaries by parsing some other public dataset at build time — rejected as unnecessary; the boundary points are static enough to hand-author once from a standard reference.

## R4. Bundled asset layout

**Decision**: Replace the single `assets/quran/quran_uthmani.json` registration with:

```text
assets/quran/chapters/index.json       # from dist/chapters/en/index.json (R2)
assets/quran/chapters/1.json … 114.json  # from dist/chapters/{n}.json (R2)
assets/quran/juz_boundaries.json       # new static table (R3)
```

`pubspec.yaml`'s `assets:` list registers `assets/quran/chapters/` as a directory (Flutter includes all files directly inside a registered directory, and every file here sits flat in that one folder) plus `assets/quran/juz_boundaries.json` individually — replacing the current single-file entry.

**Rationale**: One file per Surah (per the brief's explicit performance goal) plus one combined list file, matching the brief's two-file-shapes instruction ("per-surah local files" + "a json source file for the Quran Surahs list for the two types of view") while keeping registration flat and simple (no recursive directory needed, since `risan/quran-json`'s own `chapters/` layout is already flat).

## R5. `QuranRepositoryImpl` — load-once-reuse-forever becomes read-from-bundle-once-reuse-forever

**Decision**: `getSurahList()`, `getJuzSections()`, and `getSurah(int)` keep the exact same Hive-cache-first check and public signatures as today (004 research R2's "fetch once, reuse forever" caching), but the "fetch" step becomes "parse the relevant bundled JSON file(s) via `rootBundle.loadString`" instead of a `DioClient` request, and there is no fallback branch left to design (R1) — a bundled file is either present and parses (it always is, being shipped with the app) or, defensively, is missing/corrupt, in which case the method throws (mapped to `QuranUnavailableState`/`SurahReadingUnavailableState`, per FR-007/edge cases) exactly like today's "neither remote nor fallback" terminal case. `getSurah(int)` now loads only `assets/quran/chapters/$surahNumber.json` — never the other 113 files — directly satisfying FR-004/SC-003's per-Surah isolation goal.

**Rationale**: Keeps `QuranRepository`'s public interface, and therefore every domain/presentation-layer consumer (`QuranCubit`, `SurahReadingCubit`, both page widgets), completely unchanged — matching the brief's explicit architecture instruction. Only `QuranRepositoryImpl` and the `SurahModel`/`AyahModel` `fromJson`-style mapping methods (which already isolate the "what shape did this JSON come in as" concern) change.

**Alternatives considered**: None — this is a direct, minimal-surface-area data-layer swap, not a design decision with real alternatives.

## R6. Font family set and new default

**Decision**: `QuranFontSetting.availableFontFamilies` becomes `['Amiri', 'Kitab', 'MeQuran', 'QPCHafs']` (4 entries, replacing today's `['Lateef', 'Amiri', 'QPCHafs']`). All 4 font files are already bundled and registered as font families in `pubspec.yaml` (`Amiri`, `Kitab`, `MeQuran`, `QPCHafs` — verified present today; no new font asset sourcing needed, unlike 004 research R9). `QuranFontSetting.defaults.fontFamily` changes from `'Lateef'` to `'QPCHafs'` — the standard King Fahd Complex "Hafs" Uthmani typeface, continuing 004 research R9's own stated reasoning for why QPCHafs was chosen as the closest match to a Uthmani default.

**Rationale**: Matches spec.md FR-001 exactly (the 4 named families). QPCHafs as the new default keeps the "default = standard Uthmani script" intent that motivated the original default, now that Lateef (a Naskh-style general-purpose Arabic font, not Quran-specific) is dropped from the set entirely.

## R7. Migrating a user's stale saved font family

**Decision**: `QuranRepositoryImpl.getFontSetting()` validates the Hive-stored `fontFamily` against `QuranFontSetting.availableFontFamilies`; if it isn't a member (e.g. a pre-update user has `'Lateef'` saved), it substitutes `QuranFontSetting.defaults.fontFamily` and persists the corrected value back (local Hive always; also to `user_preferences` if `SessionCubit.instance.currentUser?.id` is non-null) so the stale value isn't re-read on every subsequent load.

**Rationale**: Directly satisfies FR-006/User Story 2 acceptance scenario 4 (automatic migration, no error, no user action).

## R8. Font-settings sheet per-family labels — implementation-time detail, not a data-source concern

**Decision**: `QuranFontSettingsSheet._labelFor(String fontFamily)` currently special-cases only `AppTypography.quranFontFamily` ('Lateef', "Naskh · default") vs. every other family ("Uthmani"). With Lateef removed and all 4 remaining families being dedicated Quran/Uthmani-style typefaces, this switch needs a per-family (or single shared) label rewrite. This is presentation-layer text, not a repository/data-source change, and is called out explicitly here so `/speckit-tasks` carries it as its own visible task rather than it being missed as a side effect of the entity change.

**Rationale**: The widget already iterates `QuranFontSetting.availableFontFamilies` dynamically (confirmed by reading `quran_font_settings_sheet.dart`), so the card count adjusts to 4 automatically — the only code that needs a deliberate look is this label helper, keeping the "no critical UI changes" scope from spec.md's Input honest (this is a label-text fix, not a layout change).

## R9. Home screen "Ayah of Today" is unaffected

**Decision**: `AyahRepositoryImpl`'s use of `AppEndPoints.quranCloudAyah(...)` (`lib/features/home/`) is a separate repository and feature; nothing in this plan touches it.

**Rationale**: Matches spec.md's Assumptions section explicitly.
