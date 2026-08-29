# Implementation Plan: Quran Paged Reading

**Branch**: `009-quran-paged-reading` | **Date**: 2026-08-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-quran-paged-reading/spec.md`

## Summary

Replace the Surah Reading screen's continuous per-surah scroll with a 604-page Mushaf-style `PageView`: each page is a fixed, precomputed ayah range (never split mid-ayah, occasionally spanning two surahs), rendered with the user's existing font settings, horizontally swipeable (right-to-left = next), with `PageView`'s own bounded `itemCount` giving boundary clamping (FR-009) for free. A new jump bottom sheet (page-number entry or Juz grid) navigates directly via `PageController.jumpToPage`. Overflowing pages get an independent vertical `SingleChildScrollView` per page. Built entirely additively on the existing `QuranRepository`/`AyahModel`/`AyahTextView` (new methods and an optional field, no signature breaks), using the newly bundled `page_boundaries.json` (604-entry page→ayah-range index, already generated and validated: 604/604 pages, 6236/6236 ayat, zero split ayahs) plus the `page` field now embedded in each `assets/quran/chapters/{n}.json` ayah.

## Technical Context

**Language/Version**: Dart (SDK `^3.5.3`), Flutter (stable channel matching `pubspec.yaml`)

**Primary Dependencies**: `flutter_bloc` (extends the existing feature-scoped `SurahReadingCubit`), `flutter_svg` (4 new line icons, sourced directly from the imported design's inline SVG markup — same origin as the existing `share.svg`/`bookmark.svg`). No new packages — `PageView`/`PageController` are core Flutter widgets.

**Storage**: Hive via `SharedPrefHandler`, extending the existing permanent Quran cache. One new cache key (page boundaries, ~604 small entries) and one **cache-key version bump** for the existing per-surah ayah cache (`quranSurahCachePrefix`) — required because the updated bundled `chapters/{n}.json` files now carry a `page` field that pre-existing on-device caches (written before this update) do not have; without the bump, an already-cached surah would silently keep serving ayahs with no page number and break navigation for existing installs (research.md R5).

**Testing**: `bloc_test`/unit tests for the extended `SurahReadingCubit` (page resolution, next/previous/boundary-crossing/no-op-at-edges, jump-to-page, jump-to-juz) and for the new pure page-assembly logic in `QuranRepositoryImpl` (mixed-surah pages), per Constitution Principle VIII.

**Target Platform**: iOS + Android (Flutter mobile app). Page rendering is pure Flutter/Dart — no platform-specific code.

**Performance Goals**: A swipe renders the adjacent page in under 1 second (spec.md SC-001); satisfied by construction since all Quran content is already bundled/cached locally (no network) and a single page's ayah slice is a cheap in-memory filter over an already-cached surah's ayah list.

**Constraints**: Fixed at exactly 604 pages, matching the standard Madani Mushaf layout already reflected in the updated bundled assets (spec.md Assumptions) — this plan does not compute page boundaries itself, only consumes the precomputed `page_boundaries.json`. No reading-progress persistence (spec.md FR-015). Must not modify `lib/shared/`, `lib/handlers/`, `lib/network/`, or `lib/configurations/`'s existing structure/patterns beyond the two already-established extension points (one new `AppPersistenceDataKeys` entry, new `TranslationKeys` entries) — all pagination logic lives inside the `quran` feature's own `domain`/`data`/`presentation` layers (constitution Principle I already scopes business logic to the feature; this is that principle applied, not an exception to "no big core-layer changes").

**Scale/Scope**: One rewritten screen body (`SurahReadingView` → `PageView`-based), one extended repository (3 new additive methods), one extended domain entity (`Ayah` gains an optional `pageNumber`) plus one new entity (`MushafPage`), one extended feature-scoped cubit, 4 new SVG icons + 2 new small widgets (jump bottom sheet, surah-transition divider), one new 3-button reading-actions bar (share/tafseer/listen — no-op stubs per spec, no bookmark).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design — still passes, no new violations introduced by the design artifacts below.*

| Principle | Check | Result |
|---|---|---|
| I. Feature-First, Complexity-Scaled Architecture | Quran is already a full Clean Architecture feature (real domain logic: page assembly, boundary math) — stays that way; all new code lives under `lib/features/quran/{domain,data,presentation}`. Checked `lib/shared/bloc/` first per Development Workflow step 1 — nothing there owns Quran pagination, confirming this belongs in the feature. | PASS |
| II. BLoC/Cubit State Management | No new state-management library. `SurahReadingCubit` keeps its existing feature-scoped (non-singleton) pattern, gains typed methods; `SurahReadingState`'s loaded variant is restructured (still a plain `sealed class` hierarchy, no new pattern). | PASS |
| III. No Service-Locator DI | No `get_it`/`injectable`. `SurahReadingCubit` continues to be constructed directly with a `QuranRepositoryImpl()`, same as today. | PASS |
| IV. Centralized Design System | Zero new colors/typography — every token the design uses (`--brand-primary`, `--surface`, `--border`, `--text-primary/secondary`, `--bg`, `--surface-raised`) already has a direct `AppColors` counterpart, already proven in this exact design doc for two prior features. 4 new icon keys added to `AppIcons` before use (research.md R6), matching the existing SVG-icon convention exactly (`share.svg` already matches this design 1:1). | PASS |
| V. Reusable Widgets Over Inline Build Methods | New non-trivial UI (`MushafPageView`/page item, jump bottom sheet, Juz grid, surah-transition divider, reading-actions bar) each gets its own widget class under `presentation/widgets/`, not inline `_buildX()` methods in the page. `AyahTextView` is reused as-is for rendering a page's ayah runs. | PASS |
| VI. Dio-Based Network Layer | Not applicable — no network calls; Quran content is 100% bundled/local, unchanged from the existing feature. | PASS (N/A) |
| VII. Configuration/Env/Localization | One new `AppPersistenceDataKeys` entry (page-boundaries cache key) plus the versioned surah-cache key, both as named constants, not raw strings. New user-facing strings (jump sheet labels, reading-actions bar labels, audio-download tooltip) added to `TranslationKeys` + both `assets/lang/{en,ar}.json`. | PASS |
| VIII. Naming/Formatting/Test Discipline | `dart format` + `flutter analyze` clean before completion; unit/`bloc_test` coverage for the new page-resolution and boundary-crossing logic (genuinely new business logic, not UI-only). | PASS |

No new dependencies (Technology Stack & Dependencies section of the constitution — `PageView`/`PageController` are Flutter SDK, not a package). No entries needed in Complexity Tracking — no principle violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/009-quran-paged-reading/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/            # Phase 1 output
│   ├── quran_repository_paging_contract.md
│   └── surah_reading_cubit_contract.md
└── tasks.md              # Phase 2 output (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

```text
assets/quran/
└── page_boundaries.json                     # NEW asset — must be added to pubspec.yaml assets list

lib/
├── configurations/
│   ├── app_persistence_data_keys.dart       # EXTENDED: quranPageBoundariesCache key; quranSurahCachePrefix value bumped (e.g. _v2)
│   └── app_translation_keys.dart            # EXTENDED: jump-sheet, reading-actions-bar, audio-tooltip keys
├── utils/
│   └── assets/
│       └── app_icons_keys.dart              # EXTENDED: 4 new icon keys (audio download, page-jump/book, listen, tafseer)
└── features/
    └── quran/
        ├── domain/
        │   ├── entities/
        │   │   ├── ayah.dart                # EXTENDED: optional pageNumber field (additive)
        │   │   └── mushaf_page.dart          # NEW: pageNumber, surahRuns (1..3 MushafPageSurahRun{surah, ayahs})
        │   └── repositories/
        │       └── quran_repository.dart     # EXTENDED: getPageBoundaries(), getPage(pageNumber), firstPageOfJuz(juzNumber) — additive
        ├── data/
        │   ├── models/
        │   │   └── ayah_model.dart           # EXTENDED: parse/persist optional 'page'
        │   └── repositories/
        │       └── quran_repository_impl.dart # EXTENDED: page-boundary loading/caching, MushafPage assembly, versioned cache key
        └── presentation/
            ├── bloc/
            │   ├── surah_reading_cubit.dart   # REWORKED (feature-local, not core): initialize/jumpToPage/jumpToJuz/onPageChanged
            │   └── surah_reading_state.dart   # REWORKED: loaded variant carries current page number + total pages
            ├── pages/
            │   ├── surah_reading_page.dart    # EXTENDED: 2 new AppBar action buttons (audio no-op, jump sheet)
            │   └── surah_reading_view.dart     # REWORKED: PageView.builder(itemCount: 604) body
            └── widgets/
                ├── ayah_text_view.dart         # UNCHANGED — reused per-page
                ├── mushaf_page_view.dart        # NEW: one page's content (start/end ayah runs, transition divider, page badge, overflow scroll)
                ├── surah_transition_divider.dart # NEW: Bismillah + new-surah name, shown mid-page on the 51 mixed pages
                ├── quran_page_jump_sheet.dart    # NEW: bottom sheet — page-number / Juz tabs
                └── quran_reading_actions_bar.dart # NEW: 3-button bar — listen/tafseer/share, all no-op (spec Assumptions)

assets/lang/
├── en.json                                  # EXTENDED
└── ar.json                                  # EXTENDED

test/
└── features/
    └── quran/
        ├── data/repositories/quran_repository_impl_test.dart  # EXTENDED: page assembly incl. the 51 mixed-surah pages
        └── presentation/bloc/surah_reading_cubit_test.dart      # EXTENDED (or new alongside existing file)
```

**Structure Decision**: Single Flutter project, existing `lib/features/quran/` Clean Architecture layout (unchanged top-level layering). All pagination logic is additive within this one feature's three layers; the only touches outside the feature are the two already-established, purpose-built extension points (`AppPersistenceDataKeys`, `TranslationKeys`) and one new icon-asset registration, none of which alter any other feature's behavior. `pubspec.yaml`'s `assets:` list gains one new explicit entry (`assets/quran/page_boundaries.json`) — `merge_pages_script.py` and `validation_report.json` (dev-tooling/provenance, not runtime data) are deliberately **not** added, so they aren't bundled into the app.

## Complexity Tracking

*No entries — Constitution Check has no violations to justify.*
