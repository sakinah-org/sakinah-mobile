# Contract: `SurahReadingCubit` (reworked)

`lib/features/quran/presentation/bloc/surah_reading_cubit.dart` — feature-scoped (constructed fresh per screen visit via `BlocProvider` in `SurahReadingPage`, **not** a singleton — unchanged from today). The existing `loadSurah(int)` method and its `{surah, ayahs}`-shaped loaded state are **replaced** by the API below (data-model.md's `SurahReadingState` restructure) — this is the feature-local cubit this feature is about, not a "core layer" change (plan.md's Constitution Check).

## Public API

```dart
SurahReadingCubit({required QuranRepository repository});

/// Entry point when arriving from the Surah list (spec.md FR-005).
/// 1. emit(SurahReadingLoadingState())
/// 2. pageNumber = await _repository.firstPageOfSurah(surahNumber)
/// 3. emit(SurahReadingLoadedState(startingPageNumber: pageNumber, totalPages: 604))
/// On any failure: emit(SurahReadingUnavailableState()) — same
/// fail-safe pattern as the current loadSurah.
Future<void> initialize(int surahNumber);

/// Resolves a Juz's first page for the jump sheet's Juz tab.
/// Returns the page number directly (does NOT emit a new state — the
/// caller (the jump sheet) is responsible for calling
/// PageController.jumpToPage(result - 1) itself; see "Who owns the
/// current page" below).
Future<int> resolveJuzFirstPage(int juzNumber);
```

## Who owns "the current page" (important — not a state field)

Unlike the pre-rework cubit (which held the loaded surah's full ayah list in state), this cubit does **not** track which page is currently visible after the initial load. That responsibility belongs to the `PageController`/`PageView` in `SurahReadingView` (data-model.md's `SurahReadingState` section) — swiping is a pure `PageView` gesture with no Cubit round-trip per page, and jumping is `PageController.jumpToPage(target - 1)` called directly by the jump sheet (using `resolveJuzFirstPage`'s return value, or the user-typed page number directly for the page-number tab).

The Cubit's `SurahReadingLoadedState.startingPageNumber` is read exactly once, to construct the `PageController(initialPage: startingPageNumber - 1)` when the `PageView` is first built — it is never re-emitted as the user swipes.

## Page content fetching (per `PageView` item, not the Cubit)

Each `PageView.builder` item fetches its own `MushafPage` directly from `QuranRepository.getPage(pageNumber)` (via a small `FutureBuilder`-based widget, e.g. `MushafPageView`), not through the Cubit. This keeps per-swipe latency to exactly one repository call (already cache-backed, no network) with no cubit `emit`/`BlocBuilder` rebuild of unrelated state in between.

## Validation

- `jumpToPage`'s target (typed by the user in the jump sheet) MUST be clamped/rejected outside 1–604 **before** calling `PageController.jumpToPage` — this is UI-layer input validation (spec.md FR-011), not a Cubit method; the Cubit is never asked to resolve an invalid page number.
- `resolveJuzFirstPage`'s `juzNumber` is always 1–30 by construction (the Juz tab only ever offers a 1–30 grid) — no additional validation needed inside the method.

## Out of scope

- No reading-progress persistence (spec.md FR-015) — `initialize` always resolves the entry point fresh (tapped Surah's first page, or the jump target when arriving via a jump), never a remembered "last page."
- Font settings (`fontFamily`/`fontSize`) continue to come from the existing, untouched `QuranFontSettingsCubit` — this cubit has no opinion on font rendering, exactly as before.
