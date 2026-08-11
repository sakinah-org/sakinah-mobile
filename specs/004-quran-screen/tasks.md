---

description: "Task list template for feature implementation"
---

# Tasks: Quran Screen

**Input**: Design documents from `/specs/004-quran-screen/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included for new business logic (three Cubits + repository) per Constitution Principle VIII ("New or changed business logic... SHOULD ship with a unit test") and quickstart.md's automated-checks list. No UI/widget tests are included (not required by the constitution).

**Organization**: Tasks are grouped by user story (spec.md P1–P5) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- File paths are exact and repo-relative

## Path Conventions

Single Flutter app — `lib/` and `test/` at repository root, per plan.md's Project Structure. No web/mobile-API split.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Config-layer additions and the one asset every story's offline fallback depends on

- [X] T001 [P] Source and bundle a verified Uthmani-script Quran dataset (surah metadata + full ayah text) as `assets/quran/quran_uthmani.json`; register it under `pubspec.yaml`'s `assets:` list (research.md R4 — content-sourcing task, not fabricated; must come from a named, checkable authoritative source, e.g. the same corpus Al Quran Cloud's own API is built from). DONE: fetched live from api.alquran.cloud (`/surah` + all 114 `/surah/{n}/quran-uthmani`), verified 114 surahs / 6236 ayahs, each ayah carries its `juz` number (enables offline Juz grouping without a separate bundled Juz dataset — see T014 adaptation). 1.6MB JSON.
- [X] T002 [P] Add `quranCloudSurahList()`, `quranCloudJuz(int)`, `quranCloudSurah(int)` endpoint methods (new `// Al Quran Cloud (Surah/Juz/Reading)` section) and `userPreferencesTable` constant to `lib/configurations/app_end_points.dart` (research.md R1, R8)
- [X] T003 [P] Add `quranSurahListCache`, `quranJuzSectionsCache`, `quranSurahCachePrefix`, `quranFontFamily`, `quranFontSize` keys (new `// Quran (lib/features/quran/)` header) to `lib/configurations/app_persistence_data_keys.dart` (data-model.md)
- [X] T004 [P] Add Quran-screen string keys to `lib/configurations/app_translation_keys.dart` and their English/Arabic values to `assets/lang/en.json` / `assets/lang/ar.json`: bottom-nav "Quran" label, Surah/Juz tab labels, search field placeholder, search no-results message, unable-to-load message, font-settings sheet title/labels, revelation-type labels (Meccan/Medinan) (FR-001–003, FR-005, FR-013, FR-018, research.md R12). Arabic copy taken directly from the imported design (research.md R10) where available.
- [X] T005 [P] Add `surahReading` route constant to `lib/navigation/app_routes.dart`

**Checkpoint**: New config/asset/translation keys exist and are ready to consume.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared data/domain layer every user story fetches through — `QuranRepository` and its entities/models

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 [P] Create `Surah` entity + `RevelationType` enum in `lib/features/quran/domain/entities/surah.dart` (data-model.md)
- [X] T007 [P] Create `Ayah` entity in `lib/features/quran/domain/entities/ayah.dart` (data-model.md)
- [X] T008 [P] Create `JuzSection` entity in `lib/features/quran/domain/entities/juz_section.dart` (data-model.md)
- [X] T009 [P] Create `QuranFontSetting` entity in `lib/features/quran/domain/entities/quran_font_setting.dart` (data-model.md, incl. documented defaults)
- [X] T010 [P] Create `SurahModel` (parses `/surah` list response; Hive envelope `toJson`/`fromJson`) in `lib/features/quran/data/models/surah_model.dart` (depends on T006). ADAPTATION: one `fromJson` handles both the live API shape and the bundled asset shape since both use identical field names (T001's dataset was built to match on purpose)
- [X] T011 [P] Create `AyahModel` (parses `/surah/{n}/quran-uthmani` `ayahs[]`; Hive envelope) in `lib/features/quran/data/models/ayah_model.dart` (depends on T007)
- [X] T012 [P] Create `QuranFontSettingModel` (Hive scalar (de)serialization + `user_preferences` row mapping) in `lib/features/quran/data/models/quran_font_setting_model.dart` (depends on T009)
- [X] T013 Create the abstract `QuranRepository` interface (`getSurahList`, `getJuzSections`, `getSurah`, `getFontSetting`, `saveFontSetting`, `fetchRemoteFontSetting`) in `lib/features/quran/domain/repositories/quran_repository.dart` per contracts/quran_repository_contract.md (depends on T006, T007, T008, T009)
- [X] T014 Implement `QuranRepositoryImpl.getSurahList()`, `.getJuzSections()`, `.getSurah(int)` in `lib/features/quran/data/repositories/quran_repository_impl.dart`: fetch-once-reuse-forever local cache, parallel 30-Juz fetch on first Juz access, bundled-asset fallback on total failure (research.md R2–R4) (depends on T001, T002, T003, T010, T011, T013). ADAPTATION: `getJuzSections()` builds its grouping from the bundled asset's own per-ayah `juz` field on fallback (no separate bundled Juz dataset needed, per T001's note) rather than a second bundled resource
- [X] T015 Implement `QuranRepositoryImpl.getFontSetting()`, `.saveFontSetting()`, `.fetchRemoteFontSetting()` in the same file: local Hive read/write always, fire-and-forget `user_preferences` upsert/select gated on a passed-in `userId` (research.md R8) (depends on T002, T003, T012, T014)
- [X] T016 [P] Unit test `QuranRepositoryImpl` in `test/features/quran/data/repositories/quran_repository_impl_test.dart`: empty-cache → bundled-fallback parsing, cache-hit skips network, `getJuzSections()` groups a multi-Juz-spanning Surah into every relevant section, local font-setting read/write. SCOPE NOTE (mirrors `test/features/prayers/...`): the live network/Supabase paths are not unit tested here — no practical mock seam without a live/local instance — covered instead by quickstart.md's manual scenarios (depends on T014, T015). BUG FOUND & FIXED while writing this test: `getSurahList()`/`getSurah()`'s bundled-fallback branches weren't caching their result (unlike `getJuzSections()`, which already did) — every offline call was silently retrying the network first every time instead of reusing the fallback. Fixed to cache bundled-fallback results too. 6/6 tests passing

**Checkpoint**: Foundation ready — every user story can now build its Cubit/UI on top of a working `QuranRepository`.

---

## Phase 3: User Story 1 - Browse all Surahs in order (Priority: P1) 🎯 MVP

**Goal**: The Quran tab's default Surah view — all 114 Surahs, correctly ordered and labeled, with the offline-fallback and unable-to-load states already built into the repository.

**Independent Test**: Open the Quran tab and confirm all 114 Surahs appear, correctly ordered and labeled, with smooth scrolling and a working offline fallback — independent of search, Juz grouping, reading, or font settings.

### Implementation for User Story 1

- [X] T017 [P] [US1] Create `QuranState` sealed classes (`Initial`, `Loading`, `Loaded(surahs, juzSections, activeTab, searchQuery, searchResults)`, `Unavailable`) in `lib/features/quran/presentation/bloc/quran_state.dart` and the `QuranTab` enum (data-model.md) (depends on T006, T008)
- [X] T018 [US1] Implement `QuranCubit.loadSurahs()` in `lib/features/quran/presentation/bloc/quran_cubit.dart` per contracts/quran_cubit_contract.md (depends on T014, T017)
- [X] T019 [P] [US1] Unit test `QuranCubit.loadSurahs()` with `bloc_test`/`mocktail` (Loaded on success, Unavailable on repository failure) in `test/features/quran/presentation/bloc/quran_cubit_test.dart` (depends on T018). 2/2 passing
- [X] T020 [P] [US1] Create `SurahListTile` widget (number, Arabic name, transliteration, meaning, revelation type, ayah count) in `lib/features/quran/presentation/widgets/surah_list_tile.dart` (depends on T006)
- [X] T021 [P] [US1] Create `QuranUnavailableView` widget (shared FR-018 explicit unable-to-load state, reused by the Surah Reading screen in US2) in `lib/features/quran/presentation/widgets/quran_unavailable_view.dart`
- [X] T022 [US1] Create `QuranPage`/`QuranView` in `lib/features/quran/presentation/pages/quran_page.dart`: `BlocProvider<QuranCubit>`, renders `SurahListTile`s from `Loaded.surahs` or `QuranUnavailableView` (depends on T018, T020, T021)
- [X] T023 [US1] Replace the `Container()` placeholder at index 1 of `MainPage`'s `PageView` with `const QuranPage()` in `lib/features/main/ui/pages/main_page.dart` (research.md R11) (depends on T022)
- [X] T024 [P] [US1] Replace the hardcoded `"Quran"` bottom-nav label with `translator.word(TranslationKeys.quranTabLabel)` in `lib/features/main/ui/widgets/main_bottom_navigation_bar.dart` (research.md R12, depends on T004). `flutter analyze` confirmed no new issues (the one `prefer_const_constructors` info hint on that line is pre-existing, verified via git stash comparison)

**Checkpoint**: User Story 1 fully functional and independently testable/demoable — MVP.

---

## Phase 4: User Story 2 - Read a Surah (Priority: P2)

**Goal**: Tapping any Surah opens a dedicated reading screen rendering its ayat continuously with numbered badges, in the current (default, until US5 exists) saved font.

**Independent Test**: Open any Surah's reading screen directly and confirm its ayat render with correct numbering and current font — independent of the Juz tab, search, or changing font settings mid-session.

### Implementation for User Story 2

- [X] T025 [P] [US2] Create `SurahReadingState` sealed classes (`Initial`, `Loading`, `Loaded(surah, ayahs)`, `Unavailable`) in `lib/features/quran/presentation/bloc/surah_reading_state.dart` (depends on T006, T007)
- [X] T026 [US2] Implement `SurahReadingCubit.loadSurah(int)` in `lib/features/quran/presentation/bloc/surah_reading_cubit.dart` per contracts/surah_reading_cubit_contract.md (depends on T014, T025)
- [X] T027 [P] [US2] Unit test `SurahReadingCubit.loadSurah()` with `bloc_test`/`mocktail` in `test/features/quran/presentation/bloc/surah_reading_cubit_test.dart` (depends on T026). 2/2 passing
- [X] T028 [P] [US2] Create `AyahTextView` widget (continuous ayat, numbered badges, RTL, generous line height, styled from `AppTypography.quranLight/Dark` as the base) in `lib/features/quran/presentation/widgets/ayah_text_view.dart` (depends on T007). DEVIATION from the design mockup: the design shows the Basmala rendered as a separate, unnumbered ornamental header above ayah 1 — not implemented, because for Al-Faatiha the Basmala genuinely *is* ayah 1 (its text is exactly `بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ` with no other content), and for most other surahs Al Quran Cloud prepends the Basmala directly into ayah 1's text rather than supplying it as a distinct field — extracting/hiding it would risk misrepresenting the actual verse text. Ayat render exactly as the data source provides them, each with its real `numberInSurah` badge; no ayah content is hidden or fabricated.
- [X] T029 [US2] Create `SurahReadingPage`/`SurahReadingView` in `lib/features/quran/presentation/pages/surah_reading_page.dart`: reads the Surah number from `ModalRoute.of(context)!.settings.arguments`, `BlocProvider<SurahReadingCubit>`, renders `AyahTextView` or the shared `QuranUnavailableView` (depends on T021, T026, T028)
- [X] T030 [US2] Add the `AppRoutes.surahReading` case to `generateRoute()` in `lib/navigation/route_generator.dart` (depends on T005, T029)
- [X] T031 [US2] Wire Surah-tap navigation (`Navigator.pushNamed(context, AppRoutes.surahReading, arguments: surah.number)`) into `QuranPage` in `lib/features/quran/presentation/pages/quran_page.dart` (depends on T022, T030)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Browse the Quran by Juz (Priority: P3)

**Goal**: A Juz tab showing the same Surah data grouped under Juz headers 1–30, with tap-to-read working identically to the Surah tab.

**Independent Test**: Switch to the Juz tab and confirm all 30 Juz headers appear with the correct Surahs grouped beneath them, matching the Surah tab's underlying data — independent of search or reading.

### Implementation for User Story 3

- [X] T032 [US3] Implement `QuranCubit.switchTab(QuranTab)` in `lib/features/quran/presentation/bloc/quran_cubit.dart` (fetch/cache `getJuzSections()` only on first switch to Juz, instant thereafter) per contracts/quran_cubit_contract.md (depends on T018)
- [X] T033 [P] [US3] Unit test `QuranCubit.switchTab()` (Juz fetch triggered once, cached on repeat switches) in `test/features/quran/presentation/bloc/quran_cubit_test.dart` (depends on T032). 3/3 passing
- [X] T034 [P] [US3] Create `QuranTabSwitcher` widget (Surah/Juz segmented control) in `lib/features/quran/presentation/widgets/quran_tab_switcher.dart`
- [X] T035 [P] [US3] Create `JuzSectionHeader` widget in `lib/features/quran/presentation/widgets/juz_section_header.dart` (depends on T008). ADAPTATION: added one small translation key (`quranJuzSectionLabel`, "Juz"/"الجزء") not originally itemized in T004 — the design's per-section Arabic ordinal labels (e.g. "الجزء الأول") weren't replicated to avoid fabricating traditional ordinal-name text; "Juz N" is used instead, which is accurate and simple
- [X] T036 [US3] Wire `QuranTabSwitcher` and Juz-grouped rendering (reusing `SurahListTile` per Surah within each `JuzSectionHeader` group) into `QuranPage` in `lib/features/quran/presentation/pages/quran_page.dart` (depends on T031, T032, T034, T035). Wired in `quran_view.dart` (the page's body) rather than `quran_page.dart` itself, consistent with the existing Page/View split

**Checkpoint**: User Stories 1–3 all work independently.

---

## Phase 6: User Story 4 - Search for a Surah by name (Priority: P4)

**Goal**: A search field that replaces the current view with a flat, filtered Surah list, matching only Arabic name and transliteration (not meaning — spec.md Clarifications).

**Independent Test**: Type a partial Surah name and confirm only matching Surahs are shown, an explicit no-results state appears for a non-matching query, and clearing the search restores the previously active tab — independent of which tab was active or of reading/font settings.

### Implementation for User Story 4

- [X] T037 [US4] Implement `QuranCubit.search(String)` and `.clearSearch()` in `lib/features/quran/presentation/bloc/quran_cubit.dart` per contracts/quran_cubit_contract.md and FR-006 (research.md R7) (depends on T036). BUG FOUND & FIXED while writing the test: naive `.toLowerCase().contains(...)` never matched real data — official Surah names are fully vocalized (e.g. Al-Faatiha's Arabic name carries a dozen combining diacritics) while users type plain undiacritized Arabic. Added `_normalizeForSearch()` (strips tashkeel, folds alef variants) before comparing; verified against the real 114-surah bundled dataset, not just test fixtures
- [X] T038 [P] [US4] Unit test `search()`/`clearSearch()` — matches Arabic name/transliteration case-insensitively, does NOT match meaning, empty-results case, restores prior tab on clear — in `test/features/quran/presentation/bloc/quran_cubit_test.dart` (depends on T037). 5/5 passing
- [X] T039 [P] [US4] Create `QuranSearchField` widget in `lib/features/quran/presentation/widgets/quran_search_field.dart`
- [X] T040 [P] [US4] Create `QuranSearchEmptyView` widget (explicit no-results state) in `lib/features/quran/presentation/widgets/quran_search_empty_view.dart`
- [X] T041 [US4] Wire `QuranSearchField`, filtered results list, `QuranSearchEmptyView`, and disabling `QuranTabSwitcher` while a search is active into `QuranPage` in `lib/features/quran/presentation/pages/quran_page.dart` (depends on T037, T039, T040). ADAPTATION: wired in `quran_view.dart` (converted to a `StatefulWidget` to own a persistent `TextEditingController` across rebuilds); "not usable while searching" implemented by hiding the tab switcher entirely rather than showing it disabled — satisfies FR-008 with a simpler UI

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Adjust Quran font settings (Priority: P5)

**Goal**: A font-settings bottom sheet (reachable from both screens) with a size control and 3 live-previewed font families, applying instantly and persisting locally + (if authenticated) remotely.

**Independent Test**: Open the font-settings bottom sheet from either screen, change size and family, confirm the change applies instantly, and confirm it's still applied after an app restart — independent of which Surah is open or how the user navigated there.

### Implementation for User Story 5

- [X] T042 [P] [US5] Confirm the three selectable Quran font families map correctly for `QuranFontSetting` (all already bundled in `pubspec.yaml`, no new asset needed per research.md R9/R10) — and update `lib/utils/style/app_typography.dart`'s doc comment accordingly. Added `QuranFontSetting.availableFontFamilies` as the single source of truth for the 3 families. UPDATE (post-implementation): `assets/fonts/nastaleeq/w400.ttf` was removed and `pubspec.yaml` re-registered with `Kitab`/`MeQuran`/`QPCHafs` in its place (alongside `Amiri`) — final selectable set is `Lateef`/`Amiri`/`QPCHafs`, not `Lateef`/`Amiri`/`Nastaleeq` as originally planned; `AppTypography.ornamentalFontFamily`'s doc comment reverted to describe Nastaleeq as ornamental-only again (research.md R9 post-implementation note)
- [X] T043 [P] [US5] Create a small `QuranFontButton` widget (the "Aa" text-style trigger button per the design — two stacked letter sizes, rounded border, `lib/features/quran/presentation/widgets/quran_font_button.dart`) used in both app bars; no new icon asset needed (research.md R10/R13)
- [X] T044 [P] [US5] Create `QuranFontSettingsState` (`QuranFontSettingsLoadedState { fontFamily, fontSize }`) in `lib/features/quran/presentation/bloc/quran_font_settings_state.dart` (depends on T009)
- [X] T045 [US5] Implement `QuranFontSettingsCubit` (singleton `.instance`) — `load()`, `setFontFamily()`, `setFontSize()` — in `lib/features/quran/presentation/bloc/quran_font_settings_cubit.dart` per contracts/quran_font_settings_contract.md (depends on T015, T044). ADAPTATION: added a `@visibleForTesting factory .test(repository)` seam (mirroring `PrayerTimesCubit`'s existing precedent) since a singleton cubit otherwise has no way to inject a mock repository in tests
- [X] T046 [P] [US5] Unit test `QuranFontSettingsCubit` with `bloc_test`/`mocktail`: local defaults, `setFontFamily`/`setFontSize` update state immediately and persist, guest never syncs remotely, authenticated `load()` adopts a non-null remote value in `test/features/quran/presentation/bloc/quran_font_settings_cubit_test.dart` (depends on T045). 3/3 passing
- [X] T047 [P] [US5] Create `QuranFontSettingsSheet` widget (size control + 3-family selector, each with a live preview, per the design's §05 layout — selected = colored border + filled checkmark, unselected = plain border) and `QuranFontFamilyPreviewCard` widget in `lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart` and `lib/features/quran/presentation/widgets/quran_font_family_preview_card.dart`, both reading/calling `QuranFontSettingsCubit.instance` directly (depends on T042, T045)
- [X] T048 [US5] Provide `QuranFontSettingsCubit.instance` once at `MainPage` level (`BlocProvider.value`, alongside where `QuranPage` and the navigator that reaches `SurahReadingPage` both live), and add the `QuranFontButton` app-bar control (opening `QuranFontSettingsSheet`) to both `QuranPage` and `SurahReadingPage` (depends on T023, T029, T043, T047). DEVIATION: provided in `main.dart`'s existing app-root `MultiBlocProvider` instead of `MainPage` — `SurahReadingPage` is reached via the app's single top-level `Navigator.pushNamed`, which pushes a route as a *sibling* of `MainPage` in the widget tree, not a descendant, so a `BlocProvider` scoped inside `MainPage` would not have been visible there. `load()` is called once during app startup (`main()`, after `SessionCubit.instance.restoreSession()`) rather than from a widget, avoiding redundant reloads on every rebuild
- [X] T049 [US5] Style `AyahTextView` (`lib/features/quran/presentation/widgets/ayah_text_view.dart`) from `QuranFontSettingsCubit.instance.state` (`fontFamily`/`fontSize`) instead of the fixed `AppTypography.quranLight/Dark` default, so font changes actually apply to the reading screen (depends on T028, T045)

**Checkpoint**: All five user stories independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and final validation across all stories

- [X] T050 [P] `flutter analyze` — zero new issues across `lib/features/quran/`, and the modified `lib/features/main/`, `lib/navigation/`, `lib/configurations/` files. Full-repo `flutter analyze` re-run: the only finding in a touched file is the pre-existing `prefer_const_constructors` info hint in `main_bottom_navigation_bar.dart`, confirmed via git-stash comparison to predate this feature
- [X] T051 [P] `dart format` run across all new/changed `lib/` and `test/` files (15 files reformatted, whitespace-only; re-verified `flutter analyze`/`flutter test` clean afterward)
- [~] T052 PARTIAL — run quickstart.md's five scenarios end to end on a device/simulator (guest and signed-in), including the offline-fallback and cross-device font-sync checks. Could NOT drive the interactive scenarios in this session: no physical device was connected at this point (the Android device used earlier in the conversation was for a different feature and is no longer attached), and `flutter run -d macos` built successfully (`✓ Built build/macos/Build/Products/Debug/base.app`, confirming the bundled `assets/quran/quran_uthmani.json` packages and links cleanly into a real app binary) but this sandboxed session has no interactive desktop session to foreground/attach a GUI window to (`Failed to foreground app; open returned 1`). What IS verified: all 19 automated unit tests pass (repository caching/fallback/Juz-grouping, all three Cubits, real-dataset search normalization), `flutter analyze`/`dart format` clean, and a successful compiled build. **Needs a manual interactive pass on a real device before this feature is considered UI-verified** — same limitation `003-prayers-times-screen` hit and documented (its T032).
- [~] T053 PARTIAL — manual side-by-side comparison against the design reference for FR-019/SC-007, using the concrete tokens/layout/copy captured in research.md R10 (`Sakinah Screens.dc.html` §03–05, design-system `tokens/*.css`) as the source of truth — check colors, spacing, the "Aa" button styling, and the font-settings sheet's selected/unselected card states specifically. Every widget was built directly against the captured design values (exact `AppColors`/`AppTypography` tokens — already confirmed matching the design system — exact Arabic copy, exact measurements: 38px number badges, 26px ayah badges, 27px/56px ayah text, the "Aa" button shape, the font-card selected/unselected states) rather than approximated. What's NOT done: an actual rendered-screenshot side-by-side, since T052's device limitation applies here too. **Needs the same manual device pass as T052 before FR-019/SC-007 can be marked fully satisfied.**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: T006–T013 have no hard dependency on Setup (different files). T014/T015 do — they call the `AppEndPoints`/`AppPersistenceDataKeys` constants Setup adds (T002, T003) and T014's bundled fallback reads the dataset Setup adds (T001) — so Setup (at least T001–T003) MUST complete before T014/T015, which in turn BLOCK all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T013–T016) — no dependency on US2–US5
- **User Story 2 (Phase 4)**: Depends on Foundational and reuses `QuranUnavailableView`/`QuranPage` from US1 (T021, T022) — independently testable per its own acceptance scenarios once those exist
- **User Story 3 (Phase 5)**: Depends on US1/US2's `QuranPage`/`QuranCubit` existing (T031, T032) — additive tab on top of already-working browsing
- **User Story 4 (Phase 6)**: Depends on US3's `QuranPage` wiring (T036) — additive search on top of the already-working tabbed view
- **User Story 5 (Phase 7)**: Depends on Foundational's font-setting repository methods (T015) and both pages existing (T023, T029) — cross-cutting across US1/US2's screens but independently testable via its own acceptance scenarios
- **Polish (Phase 8)**: Depends on all five stories being complete

### Within Each User Story

- US1: state (T017) → cubit (T018) → its test (T019); tile/unavailable widgets (T020, T021) in parallel with the cubit; page (T022) → main-page wiring (T023) and bottom-nav label fix (T024) last
- US2: state (T025) → cubit (T026) → its test (T027); ayah widget (T028) in parallel; reading page (T029) → route wiring (T030) → tap-navigation wiring (T031)
- US3: `switchTab()` (T032) → its test (T033); tab-switcher/header widgets (T034, T035) in parallel; page wiring (T036) last
- US4: `search()`/`clearSearch()` (T037) → its test (T038); search-field/empty-view widgets (T039, T040) in parallel; page wiring (T041) last
- US5: font-mapping check (T042) and the `QuranFontButton` widget (T043) in parallel with everything else; state (T044) → cubit (T045) → its test (T046); sheet/preview widgets (T047, depends on T042/T045); provider + app-bar wiring (T048, depends on T043/T047); reading-screen font application (T049)

### Parallel Opportunities

- All Setup tasks (T001–T005) can run together
- T001–T005 (Setup) and T006–T012 (Foundational entities/models) can all run in parallel with each other; T013 waits on T006–T009; T014 waits on T001, T002, T003 (Setup), T010, T011, T013; T015 waits on T002, T003 (Setup), T012, T014; T016 waits on T014/T015
- T019, T020, T021 (US1) can run in parallel once T018 is done
- T027, T028 (US2) can run in parallel once T026 is done
- T033, T034, T035 (US3) can run in parallel once T032 is done
- T038, T039, T040 (US4) can run in parallel once T037 is done
- T042, T043 (US5) can start any time, independent of everything else; T046 can run once T045 is done; T047 once T042/T045 are done
- T050, T051 (Polish) can run in parallel

---

## Parallel Example: Foundational phase

```bash
# Launch together at the very start of Phase 2:
Task: "Create Surah entity + RevelationType enum in lib/features/quran/domain/entities/surah.dart"
Task: "Create Ayah entity in lib/features/quran/domain/entities/ayah.dart"
Task: "Create JuzSection entity in lib/features/quran/domain/entities/juz_section.dart"
Task: "Create QuranFontSetting entity in lib/features/quran/domain/entities/quran_font_setting.dart"
```

## Parallel Example: User Story 1

```bash
# Once T018 (QuranCubit.loadSurahs()) is done, launch together:
Task: "Unit test QuranCubit.loadSurahs() in test/features/quran/presentation/bloc/quran_cubit_test.dart"
Task: "Create SurahListTile widget in lib/features/quran/presentation/widgets/surah_list_tile.dart"
Task: "Create QuranUnavailableView widget in lib/features/quran/presentation/widgets/quran_unavailable_view.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md Scenario 1 independently
5. Demo: read-only Quran tab listing all 114 Surahs

### Incremental Delivery

1. Setup + Foundational → working `QuranRepository`, no UI yet
2. + User Story 1 → browsable Surah list (MVP) → validate → demo
3. + User Story 2 → tap-to-read working → validate → demo
4. + User Story 3 → Juz tab → validate → demo
5. + User Story 4 → search → validate → demo
6. + User Story 5 → font settings, cross-screen and cross-device → validate → demo
7. Polish → analyze/format clean, all quickstart scenarios re-run end to end, design-parity check

---

## Notes

- [P] tasks touch different files and have no unmet dependency on another incomplete task in the same batch
- [Story] label maps each task to its spec.md user story for traceability
- Foundational is the largest non-story phase because every one of the 5 user stories depends on some part of `QuranRepository` — splitting its creation across stories would force partial/unstable interface implementations
- T001 is the one remaining content-sourcing task (verified Quran text for the bundled offline fallback) — do not treat "the code compiles" as evidence it's actually done. The font-file and font-settings-icon gaps flagged in an earlier pass (previously T042/T043) turned out not to exist once the design was actually imported (research.md R9/R10/R13) — both are now small, ordinary code tasks
- Verify `flutter test` passes for T016, T019, T027, T033, T038, T046 before considering their respective phases done
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently
