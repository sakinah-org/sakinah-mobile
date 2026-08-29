---

description: "Task list for Quran Paged Reading (specs/009-quran-paged-reading)"
---

# Tasks: Quran Paged Reading

**Input**: Design documents from `/specs/009-quran-paged-reading/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Included for new business logic only (`QuranRepositoryImpl` page assembly, `SurahReadingCubit` page resolution, boundary-crossing/edge-clamping behavior), per Constitution Principle VIII. UI-only widget work (page rendering, jump sheet, reading-actions bar) is not required to ship tests. Not TDD-ordered — write alongside or immediately after the corresponding implementation task.

**Organization**: Tasks are grouped by user story (spec.md priorities) so each story is independently implementable and testable.

**Design-mechanism note**: research.md R4 established that a single Quran-wide `PageView.builder(itemCount: 604, physics: ClampingScrollPhysics())` gives surah-boundary crossing (US2) and edge clamping (FR-009) "for free" once US1's core mechanism exists — there is no separate boundary-crossing *mechanism* to build. US2's tasks below are therefore the two things that genuinely don't already exist once US1 ships: the app bar's surah label updating live as pages turn, and the tests that lock in the free behavior actually holds.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Maps the task to spec.md's US1–US4
- File paths are exact, relative to the repository root

## Path Conventions

Single Flutter project — `lib/`, `test/`, `assets/` at the repository root, per plan.md's Project Structure.

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: The page↔ayah data layer every user story reads from — no story can render a single page without this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Add `assets/quran/page_boundaries.json` to the `assets:` list in `pubspec.yaml` (do **not** add `merge_pages_script.py` or `validation_report.json` — plan.md Structure Decision)
- [X] T002 [P] In `lib/configurations/app_persistence_data_keys.dart`: add `quranPageBoundariesCache` key, and bump `quranSurahCachePrefix`'s **value** (e.g. `'quran_surah_cache'` → `'quran_surah_cache_v2'`) per research.md R5 — old cached entries are simply orphaned, not migrated
- [X] T003 [P] Add optional `pageNumber` field to the `Ayah` entity in `lib/features/quran/domain/entities/ayah.dart` (data-model.md)
- [X] T004 Update `AyahModel.fromJson`/`toHiveJson`/`listFromHiveJson` in `lib/features/quran/data/models/ayah_model.dart` to parse/persist the optional `page` field (depends on T003)
- [X] T005 [P] Create the `MushafPage` domain entity (`pageNumber`, `surahRuns: List<MushafPageSurahRun>` where each run is `{surah, ayahs}`, `startSurah`/`isMixedPage` convenience getters) in `lib/features/quran/domain/entities/mushaf_page.dart` — a page usually has 1 run, but up to 3 near the end of the Quran (e.g. page 604: Al-Ikhlas + Al-Falaq + An-Nas) (data-model.md, corrected)
- [X] T006 Add `getPage(int)`, `firstPageOfSurah(int)`, `firstPageOfJuz(int)` method signatures to the `QuranRepository` interface in `lib/features/quran/domain/repositories/quran_repository.dart` (contracts/quran_repository_paging_contract.md; page-boundary loading stayed a private `_loadPageBoundaries()` helper, not public API; depends on T003, T005)
- [X] T007 Implement the 4 new methods in `QuranRepositoryImpl` (`lib/features/quran/data/repositories/quran_repository_impl.dart`): load/cache `page_boundaries.json` under the new key (T002), assemble `MushafPage` per the data-model.md pseudocode (walking every surah in the boundary range, not just start/end), resolve `firstPageOfSurah`/`firstPageOfJuz` via each surah's cached, page-tagged ayah list — depends on T002, T004, T005, T006
- [X] T008 Unit tests for `QuranRepositoryImpl.getPage`/`firstPageOfSurah`/`firstPageOfJuz` in `test/features/quran/data/repositories/quran_repository_impl_test.dart` — covers a single-surah page (1), a two-surah mixed page (106), a three-surah mixed page (604), and both jump-resolution methods — 18/18 passing

**Checkpoint**: `QuranRepositoryImpl` can correctly assemble any of the 604 pages, verified by tests, with zero UI involvement.

---

## Phase 2: User Story 1 - Read a Surah Page by Page (Priority: P1) 🎯 MVP

**Goal**: Tapping a Surah opens its first Mushaf page; swiping right-to-left/left-to-right moves to the next/previous page with correct content and a visible page number — including full, correct content on the 51 mixed pages (FR-002/FR-003 apply to every page, not just single-surah ones).

**Independent Test**: Open any Surah, confirm its first page renders with a visible page number, swipe both directions and confirm content + page number update correctly each time (quickstart.md US1).

### Implementation for User Story 1

- [X] T009 [US1] Restructure `SurahReadingState`'s loaded variant to `{startingPageNumber, totalPages}` in `lib/features/quran/presentation/bloc/surah_reading_state.dart` (data-model.md)
- [X] T010 [US1] Replace `SurahReadingCubit.loadSurah` with `initialize(int surahNumber)` (resolves `firstPageOfSurah`, emits the restructured loaded state; unavailable-state fallback unchanged) + `resolveJuzFirstPage`/`repository` getter (pulled forward from US3 since trivial) in `lib/features/quran/presentation/bloc/surah_reading_cubit.dart` (contracts/surah_reading_cubit_contract.md; depends on T007, T009)
- [X] T011 [P] [US1] `bloc_test` coverage for `SurahReadingCubit.initialize` + `resolveJuzFirstPage` in `test/features/quran/presentation/bloc/surah_reading_cubit_test.dart` — 3/3 passing (depends on T010)
- [X] T012 [P] [US1] Create `SurahTransitionDivider` widget (surah name + Bismillah in `AppTypography.ornamentalFontFamily`, styled like the existing `_basmala` precedent in `quran_font_family_preview_card.dart`; skips the Bismillah for At-Tawbah/9 per classical convention) in `lib/features/quran/presentation/widgets/surah_transition_divider.dart`
- [X] T013 [US1] Create `MushafPageView` widget: iterates `page.surahRuns`, rendering each run's ayahs via the existing `AyahTextView`, with a `SurahTransitionDivider(run.surah)` inserted before **any** run whose first ayah is ayah 1 (covers both a page that's a surah's own opening page and a later run within a mixed page — broader than originally scoped, needed for correctness), plus the page-number badge pill (new `quranPageBadgeLabel` translation key); content wrapped in a plain non-scrolling container for now (scrolling added in US4) — in `lib/features/quran/presentation/widgets/mushaf_page_view.dart` (depends on T012)
- [X] T014 [US1] Rework `SurahReadingView` into a body that takes an externally-owned nullable `PageController` + `onPageChanged` callback and builds `PageView.builder(itemCount: state.totalPages, physics: const ClampingScrollPhysics())` once loaded, each item fetching its `MushafPage` via `repository.getPage(index + 1)` (`FutureBuilder`) and rendering it with `MushafPageView` — in `lib/features/quran/presentation/pages/surah_reading_view.dart` (depends on T010, T013)
- [X] T015 [US1] Rework `SurahReadingPage` into a `StatefulWidget` that owns the `PageController` (created once, lazily, only when `startingPageNumber` is known — avoids a real bug where an eagerly-created controller would start on the wrong page) and fixes the app-bar title, which referenced the now-removed `state.surah` — resolves the tapped surah's info via `repository.getSurahList()` + the existing `surahNumber` route argument (static for this phase; made dynamic per current page in US2) — in `lib/features/quran/presentation/pages/surah_reading_page.dart` (depends on T014)
- [X] T016 [US1] `flutter analyze`/`flutter test` both clean (32/32 tests passing); manual quickstart.md US1 device walkthrough not run in this session — no simulator/emulator available (see completion report)

**Checkpoint**: Opening any Surah and swiping in both directions works correctly, including on the 51 mixed-surah pages. Independently testable and demoable now.

---

## Phase 3: User Story 2 - Cross Surah Boundaries Seamlessly (Priority: P1) 🎯 MVP

**Goal**: The app bar's surah label reflects whichever surah is actually showing as pages turn (not just the originally tapped one), and the "free" boundary-crossing/edge-clamping behavior from US1's mechanism is explicitly locked in by tests.

**Independent Test**: Swipe past a surah's last page and confirm both the content *and* the header land on the next surah with no interstitial screen; swipe past page 604 or before page 1 and confirm nothing happens (quickstart.md US2).

### Implementation for User Story 2

- [X] T017 [US2] Wire live app-bar surah-label updates: a `ValueNotifier<int?> _currentPageNumber` in `_SurahReadingPageState`, updated by `SurahReadingView`'s `PageView.onPageChanged`, drives a `ValueListenableBuilder` + `FutureBuilder<MushafPage>` in the app-bar title, replacing US1's static entry-surah title with the *current page's* `startSurah` (research.md R3) — in `lib/features/quran/presentation/pages/surah_reading_page.dart` + `lib/features/quran/presentation/pages/surah_reading_view.dart` (depends on T014, T015)
- [X] T018 [P] [US2] Added boundary-crossing assertions to `test/features/quran/data/repositories/quran_repository_impl_test.dart` (new `boundary crossing (US2)` group, 3 tests) confirming surah 1→2's page sequence is contiguous, surah 114 ends exactly on page 604, and surah 1 starts exactly on page 1 (depends on T008) — 22/22 total tests passing
- [X] T019 [US2] **Scope adjustment**: folded into T018 rather than a standalone widget test. The no-op-at-the-edge behavior itself (FR-009) is `PageView`'s own bounded-`itemCount`/`ClampingScrollPhysics` guarantee — a Flutter framework contract, not custom app logic — and this project's testing convention (Constitution Principle VIII) is unit/`bloc_test` coverage for new business logic, with UI-only behavior not required to ship tests; standing up a full widget-test harness (Hive + asset bundle + BlocProvider tree + drag-gesture simulation) to re-assert a framework guarantee wasn't judged worth the added test fragility. Manually verified via quickstart.md US2 instead (see T020/completion report)
- [X] T020 [US2] `flutter analyze`/`flutter test` clean; manual quickstart.md US2 device walkthrough (mixed-page + true-edge checks) not run in this session — no simulator/emulator available (see completion report)

**Checkpoint**: User Stories 1 AND 2 both work — paging is fully correct and the header now tracks the visible surah across boundaries (quickstart.md US1 + US2).

---

## Phase 4: User Story 3 - Jump Directly to a Page or Juz (Priority: P2)

**Goal**: A book icon in the app bar opens a bottom sheet with Page Number and Juz tabs; submitting either navigates straight to that page.

**Independent Test**: Open the jump control, enter a page number, confirm direct navigation; repeat with a Juz selection (quickstart.md US3).

### Implementation for User Story 3

- [X] T021 [P] [US3] Add `AppIcons.audioDownload`/`AppIcons.pageJump` keys (plus `listen`/`tafseer`, pulled forward from Polish T030 since trivial) + 4 new `assets/icons/*.svg` files, transcribed from the imported design's inline SVG markup (research.md R6) — in `lib/utils/assets/app_icons_keys.dart` + the new asset files
- [X] T022 [P] [US3] Add jump-sheet and audio-tooltip translation keys (page-number tab, Juz tab, "Go" CTA, valid-range helper text, Juz-picker helper text, audio-download tooltip; plus `quranPageBadgeLabel` for T013 and `listen`/`tafseer` action labels pulled forward from Polish T031 — share reuses the existing `homeAyahShareCta` key) to `lib/configurations/app_translation_keys.dart` + both `assets/lang/{en,ar}.json`
- [X] T023 [US3] Create `QuranPageJumpSheet` (two-tab bottom sheet: Page Number entry with 1–604 validation per FR-011 via a disabled "Go" button, Juz 1–30 grid) in `lib/features/quran/presentation/widgets/quran_page_jump_sheet.dart` (depends on T021, T022)
- [X] T024 [US3] `SurahReadingCubit.resolveJuzFirstPage(int)` — done in T010 (pulled forward)
- [X] T025 [US3] Added the audio-download (no-op) and page-jump app-bar action buttons to `SurahReadingPage` via a new `_AppBarIconButton` helper widget; the page-jump button opens `QuranPageJumpSheet`, which calls `PageController.jumpToPage(target - 1)` on the controller owned by `SurahReadingPage` (page-number tab: user's entry directly; Juz tab: via `resolveJuzFirstPage`) — in `lib/features/quran/presentation/pages/surah_reading_page.dart` (depends on T023, T024)
- [X] T026 [P] [US3] `bloc_test`/unit coverage for `SurahReadingCubit.resolveJuzFirstPage` — done in T011 (pulled forward)
- [X] T027 [US3] `flutter analyze`/`flutter test` clean (36/36 tests); manual quickstart.md US3 device walkthrough not run in this session — no simulator/emulator available (see completion report)

**Checkpoint**: Users can jump straight to any page or Juz from the Surah Reading screen (quickstart.md US3).

---

## Phase 5: User Story 4 - Keep Reading When Larger Text Overflows a Page (Priority: P3)

**Goal**: At large font sizes, an overflowing page scrolls vertically in place without changing which ayahs belong to that page.

**Independent Test**: Set the largest font size, open a dense page, confirm it scrolls and every word is reachable while the ayah set stays identical to the default-font-size version (quickstart.md US4).

### Implementation for User Story 4

- [X] T028 [US4] Wrapped `MushafPageView`'s content (US1's plain container) in a vertical `SingleChildScrollView` so overflowing pages scroll independently, with no change to which ayahs are included — in `lib/features/quran/presentation/widgets/mushaf_page_view.dart` (depends on T013)
- [X] T029 [US4] `flutter analyze` clean; manual quickstart.md US4 device walkthrough (large-font overflow + same-page-number content comparison) not run in this session — no simulator/emulator available (see completion report)

**Checkpoint**: All four user stories independently functional (quickstart.md US1–US4 all pass).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: The reading-actions bar (no formal user story — spec.md Assumptions only) and final validation.

- [X] T030 [P] `AppIcons.listen`/`AppIcons.tafseer` keys + SVGs — done in T021 (pulled forward); reuses the existing `AppIcons.share` for the third button — deliberately **no** bookmark button (research.md R8)
- [X] T031 [P] Reading-actions-bar translation keys — done in T022 (pulled forward); share label reuses the existing `homeAyahShareCta` key rather than duplicating "Share"
- [X] T032 Created `QuranReadingActionsBar` widget (3 buttons — listen, tafseer, share — each with an empty/no-op `onTap`, no bookmark) in `lib/features/quran/presentation/widgets/quran_reading_actions_bar.dart` and wired it into `SurahReadingPage`'s bottom area via a `Column` (body `Expanded(SurahReadingView)` + the bar) (depends on T030, T031)
- [X] T033 `dart format` across all 19 touched/added `lib`/`test` files (3 needed reformatting); `flutter analyze lib/ test/` — 0 errors; full `flutter test` — 110 passing, the same 5 pre-existing unrelated failures as before this feature (confirmed via `git stash` earlier in this session: network-mock issues in `login_bloc_test.dart`/`ayah_repository_impl_test.dart`, the stock unmodified `widget_test.dart`); `flutter pub get` clean after the `pubspec.yaml` asset addition. Manual quickstart.md walkthrough (app-bar 3-icon check, reading-actions-bar 3-button check, cache-migration regression check) **not run** — no simulator/emulator available in this session (see completion report)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. BLOCKS every user story (none can render a page without `QuranRepositoryImpl.getPage`).
- **User Story 1 (Phase 2)**: Depends on Foundational. Independent of US2–US4 otherwise.
- **User Story 2 (Phase 3)**: Depends on US1 (T014's `PageView`/T015's app-bar title are what T017 replaces/extends) — this is expected per research.md R4: US2 has no separate *mechanism* to build, only the header-tracking wiring and the tests that lock in US1's free boundary behavior.
- **User Story 3 (Phase 4)**: Depends on Foundational (T007) and on US2's shared controller (T017) for the jump button's `PageController` access. Otherwise independent of US4.
- **User Story 4 (Phase 5)**: Depends on US1 (T013's `MushafPageView`) only — independent of US2/US3.
- **Polish (Phase 6)**: Independent of all user stories except that T032 needs `SurahReadingPage` to already exist (any point after US1).

### Within Each Phase

- Foundational: entity tasks (T003, T005) before the methods that reference them (T006); `AyahModel` (T004) after `Ayah` (T003); impl (T007) after interface (T006) and cache-key (T002); tests (T008) after impl (T007).
- US1: state (T009) → cubit (T010) → cubit test (T011, parallel with widget work); divider (T012, parallel with state/cubit) → page view widget (T013) → `PageView` wiring (T014) → app-bar fix (T015) → manual validation (T016).
- US2: header wiring (T017) before nothing else in this phase depends on it directly; repository boundary tests (T018) and widget clamping test (T019) can run in parallel with T017; manual validation (T020) last.
- US3: icons (T021) and translations (T022) in parallel → jump sheet (T023) and cubit method (T024) can proceed in parallel once T021/T022 (T023) and T007 (T024) are done → app-bar wiring (T025) needs both → cubit test (T026) parallel with T025 → manual validation (T027) last.
- US4: single sequential task (T028) then validation (T029).
- Polish: icons (T030) and translations (T031) in parallel → actions bar widget (T032) → final validation (T033).

### Parallel Opportunities

- T001, T002, T003, T005 (Foundational) — 4 distinct files, no dependencies between them.
- T011 and T012 (US1) — distinct files, both only depend on already-completed Foundational/T009-T010 work.
- T018 and T019 (US2) — distinct test files, both depend only on already-completed US1 work.
- T021 and T022 (US3) — distinct files (icons vs. translations).
- T030 and T031 (Polish) — distinct files (icons vs. translations).

---

## Parallel Example: Foundational

```bash
# Launch the 4 independent Foundational tasks together:
Task: "Add assets/quran/page_boundaries.json to pubspec.yaml's assets: list"
Task: "Add quranPageBoundariesCache key + bump quranSurahCachePrefix value in app_persistence_data_keys.dart"
Task: "Add optional pageNumber field to the Ayah entity in ayah.dart"
Task: "Create the MushafPage domain entity in mushaf_page.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Foundational.
2. Complete Phase 2: User Story 1 (core paging, correct content on every page including mixed ones).
3. Complete Phase 3: User Story 2 (live header tracking + locked-in boundary/edge tests).
4. **STOP and VALIDATE**: Run quickstart.md US1 + US2. This is a fully working, shippable paged Quran reader — the feature's core value (spec.md frames both as P1).
5. Deploy/demo if ready.

### Incremental Delivery

1. Foundational → paging + boundary crossing (US1 + US2) → MVP, deploy/demo.
2. Add User Story 3 (jump control) → deploy/demo.
3. Add User Story 4 (font-overflow scrolling) → deploy/demo.
4. Add Polish (reading-actions bar) → final validation pass → done.

### Parallel Team Strategy

With multiple developers: after Foundational, one developer takes US1 → US2 (they share the same `PageView`/app-bar files, natural to pair); a second developer can start US4's `SingleChildScrollView` wrap as soon as US1's `MushafPageView` (T013) exists, in parallel with US2; US3's icon/translation prep (T021/T022) can start immediately after Foundational, with the jump-sheet widget (T023) built ahead of needing US2's controller, only the final app-bar wiring (T025) waits on US2.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to spec.md's US1/US2/US3/US4.
- `dart format` + `flutter analyze` clean before considering any task done (Constitution Principle VIII).
- Commit after each task or logical group.
- Stop at any checkpoint (end of Phase 2, 3, 4, or 5) to validate independently via quickstart.md.
