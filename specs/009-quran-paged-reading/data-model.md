# Phase 1 Data Model: Quran Paged Reading

## Ayah *(existing entity, extended)*

`lib/features/quran/domain/entities/ayah.dart`

| Field | Type | Notes |
|---|---|---|
| `numberInSurah` | `int` | Unchanged. |
| `text` | `String` | Unchanged. |
| `pageNumber` | `int?` | **NEW**, additive. Parsed from the ayah's `page` field in the updated bundled `chapters/{n}.json`. Nullable so the type itself doesn't lie about pre-migration cached data (research.md R5) — but in practice, once the cache-key bump ships, every `Ayah` produced by `QuranRepositoryImpl` has this populated; `null` should not occur in normal operation. |

No change to `AyahModel.fromJson`'s existing two fields; `page` is read as `json['page'] as int?` (tolerant of its absence, though the updated bundled assets always include it).

## Mushaf Page *(new entity — corrected from the original 2-run design)*

`lib/features/quran/domain/entities/mushaf_page.dart` — the spec's "Mushaf Page" Key Entity, in implementation terms.

**Correction**: the original design modeled a page as at most two surah runs (`startSurah`/`endSurah`). Scanning `page_boundaries.json` found 7 pages near the end of the Quran that span **three** surahs at once (e.g. page 604: Al-Ikhlas ayah 1 → An-Nas ayah 6, passing entirely through Al-Falaq in between) — a 2-slot shape would silently drop the middle surah. `MushafPage` is generalized to an ordered list of runs instead.

| Field | Type | Notes |
|---|---|---|
| `pageNumber` | `int` | 1–604. |
| `surahRuns` | `List<MushafPageSurahRun>` | Never empty. One run per surah this page contains, in reading order. `MushafPageSurahRun = {surah: Surah, ayahs: List<Ayah>}`. |

Derived/convenience: `startSurah => surahRuns.first.surah`; `isMixedPage => surahRuns.length > 1`.

**Construction** (in `QuranRepositoryImpl`, not a `fromJson` — assembled from already-cached data, not parsed from one asset):

```
boundary = pageBoundaries[pageNumber]   // {startSurah, startAyah, endSurah, endAyah}
runs = []
for surahNumber in startSurah..endSurah (inclusive):
    ayahs = (await getSurah(surahNumber)).where(a =>
        (surahNumber != startSurah || a.numberInSurah >= startAyah) &&
        (surahNumber != endSurah   || a.numberInSurah <= endAyah))
    runs.add({surah: surahByNumber[surahNumber], ayahs})
```

**Validation rules**: `surahRuns` is never empty and no run's `ayahs` is ever empty (every page has at least one ayah, and every surah between `startSurah`/`endSurah` inclusive contributes at least one — guaranteed by the already-validated `page_boundaries.json`, `pages_indexed: 604` with no gaps). An ayah never appears split across two `MushafPage`s (guaranteed upstream by `validation_report.json`'s `ayat_seen_on_conflicting_pages: []`).

## Page Boundary *(new, internal — not a domain entity, a repository-internal lookup value)*

Parsed once from `assets/quran/page_boundaries.json` and cached permanently (same pattern as `getSurahList`/`getJuzSections`).

| Field | Type |
|---|---|
| `pageNumber` | `int` (the map key, 1–604) |
| `startSurah` | `int` |
| `startAyah` | `int` |
| `endSurah` | `int` |
| `endAyah` | `int` |

Kept as a plain `Map<int, Map<String,dynamic>>` (or a tiny private record/class) inside `QuranRepositoryImpl` — not exposed as a public domain entity, since callers only ever need the assembled `MushafPage`, not the raw boundary record.

## Juz *(existing entity, unchanged)*

No shape change. Gains one new derived capability: `firstPageOfJuz(juzNumber)` resolves a Juz's `{startSurah, startAyah}` (from the already-loaded `juz_boundaries.json`) to a page number by finding the ayah with that `numberInSurah` in `getSurah(startSurah)` and reading its `pageNumber`.

## SurahReadingState *(existing, restructured — presentation-layer, not persisted)*

`lib/features/quran/presentation/bloc/surah_reading_state.dart`

| State | Fields | Replaces |
|---|---|---|
| `SurahReadingInitialState` | — | unchanged |
| `SurahReadingLoadingState` | — | unchanged |
| `SurahReadingLoadedState` | `startingPageNumber: int`, `totalPages: int` (=604) | old `{surah, ayahs}` shape — the loaded state no longer holds ayah content directly; each `PageView` item fetches its own `MushafPage` on demand (research.md R4's per-item, cache-backed model) |
| `SurahReadingUnavailableState` | — | unchanged |

`totalPages` is carried in state (rather than hardcoded `604` in the widget tree) so the `PageView`'s `itemCount` has a single source of truth alongside the rest of the loaded data, and so a future change to the boundary dataset's size doesn't require a UI-layer edit.

**State transitions**:

```
[entry via surah tap] --initialize(surahNumber)--> resolve firstPageOfSurah(surahNumber) --> Loaded(startingPageNumber, 604)
[swipe / onPageChanged(newIndex)] --> no state transition (current page is PageView-owned; MushafPage fetched per-item)
[jump control submit] --> PageController.jumpToPage(target-1) (UI-level; Loaded state's startingPageNumber is not re-emitted)
```

Current-page display (app bar surah label, page-number badge) is driven by `PageView`'s own `onPageChanged` callback updating local widget state (or a lightweight `ValueNotifier<int>` held alongside the `PageController`) — **not** re-emitted through the Cubit on every swipe, since that would mean an async repository round-trip (even a cached one) on every single-page swipe. The Cubit remains the source of truth only for the *entry point* (which page to start on) and for jump-target *resolution* (Juz → page number), both of which are one-shot lookups, not per-frame/per-swipe state.
