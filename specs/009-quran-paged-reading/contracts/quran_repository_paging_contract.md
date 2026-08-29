# Contract: `QuranRepository` paging additions

`lib/features/quran/domain/repositories/quran_repository.dart` (interface) / `lib/features/quran/data/repositories/quran_repository_impl.dart` (implementation). All existing methods (`getSurahList`, `getJuzSections`, `getSurah`, `getFontSetting`, `saveFontSetting`, `fetchRemoteFontSetting`) are **unchanged** — this contract only covers the new, additive surface.

## New public API

```dart
/// Assembles and returns the MushafPage for [pageNumber] (1–604).
/// 1. boundary = (await _loadPageBoundaries())[pageNumber] — a private
///    helper (not public API) that caches the 604-entry page→ayah-range
///    index from assets/quran/page_boundaries.json under
///    AppPersistenceDataKeys.quranPageBoundariesCache, load-once-reuse-forever.
/// 2. Walks every surah number from boundary.startSurah to
///    boundary.endSurah inclusive (usually one, up to three near the end
///    of the Quran — data-model.md's correction), building one
///    MushafPageSurahRun per surah from its already-cached getSurah(n),
///    filtered to boundary.startAyah/.endAyah at the first/last surah only.
/// Throws ArgumentError if pageNumber is outside 1–604 (caller's
/// responsibility to only ever pass a validated value — see the Cubit
/// contract's jumpToPage clamping). Same failure mapping as getSurahList
/// for a missing/corrupt page_boundaries.json (UnknownFailure — should
/// not occur in practice).
Future<MushafPage> getPage(int pageNumber);

/// Resolves a Surah's first Mushaf page: the pageNumber of that Surah's
/// ayah 1, i.e. (await getSurah(surahNumber)).first.pageNumber.
/// Used for the "tap a Surah card" entry point (spec.md FR-005).
Future<int> firstPageOfSurah(int surahNumber);

/// Resolves a Juz's first Mushaf page. Reads {startSurah, startAyah} for
/// [juzNumber] from the same juz_boundaries.json asset getJuzSections()
/// already loads/caches, finds the matching Ayah in
/// (await getSurah(startSurah)), and returns its pageNumber.
/// juzNumber MUST be 1–30 (caller's responsibility — the Juz grid in the
/// jump sheet only ever offers 1–30).
Future<int> firstPageOfJuz(int juzNumber);
```

`PageBoundary` is an internal shape (see data-model.md), not exported as a domain entity — it exists only inside the repository/impl boundary; callers only ever see the assembled `MushafPage`.

## Cache keys (new)

- `AppPersistenceDataKeys.quranPageBoundariesCache` — the 604-entry boundary map, cached permanently (load-once-reuse-forever, same policy as `quranSurahListCache`/`quranJuzSectionsCache`).
- `AppPersistenceDataKeys.quranSurahCachePrefix`'s **value** changes (e.g. `'quran_surah_cache'` → `'quran_surah_cache_v2'`) — not a new key, a bump of the existing one (research.md R5). No code outside `QuranRepositoryImpl` reads this constant's literal value, so the bump is invisible to every other caller of `getSurah(int)`.

## Failure mapping (unchanged pattern)

Same as the existing `getSurahList`/`getJuzSections`/`getSurah` methods: no network I/O anywhere in this contract, so no `DioException` path; a missing/corrupt bundled asset is the only failure mode, mapped to `UnknownFailure` via the existing `_loadAndDecode<T>` helper. `getPage`'s `MushafPage` assembly step performs no I/O of its own beyond the `getSurah`/`getPageBoundaries` calls it composes, so it inherits their failure behavior — it does not need its own try/catch.

## Consumers

- `SurahReadingCubit.initialize(surahNumber)` → `firstPageOfSurah`.
- `SurahReadingCubit`'s jump-to-Juz path → `firstPageOfJuz`.
- Each `PageView` item (via a small per-item async widget) → `getPage(pageNumber)`.

## Out of scope

- No change to how `getSurahList()`/`getJuzSections()` are computed — only `getSurah(int)`'s cache key changes (its parsing logic is unchanged; `AyahModel.fromJson` gains the optional `page` field per data-model.md, but the surrounding `getSurah` method body is otherwise untouched).
- No new Supabase/remote surface — paging is 100% local, matching the rest of this repository.
