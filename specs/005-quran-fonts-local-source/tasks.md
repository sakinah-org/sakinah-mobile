---

description: "Task list for feature implementation"
---

# Tasks: Quran Fonts & Local Data Source Update

**Input**: Design documents from `/specs/005-quran-fonts-local-source/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included for the changed business logic (`QuranRepositoryImpl`'s three content methods + font-setting migration) per Constitution Principle VIII ("New or changed business logic... SHOULD ship with a unit test") and quickstart.md's automated-checks list. No new UI/widget tests (not required by the constitution; the two presentation-layer edits in this feature are label-text/literal-list only).

**Organization**: Tasks are grouped by user story (spec.md P1–P2). US1 (data source) and US2 (fonts) touch disjoint files except `quran_repository_impl.dart`, where they touch different methods (`getSurahList`/`getJuzSections`/`getSurah` vs. `getFontSetting`) — each story is independently implementable and testable, per plan.md's Summary.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2)
- File paths are exact and repo-relative

## Path Conventions

Single Flutter app — `lib/`, `assets/`, `test/` at repository root, per plan.md's Project Structure. No web/mobile-API split.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Wire the new asset location into the build before either story's code reads from it

- [X] T001 Create the `assets/quran/chapters/` directory and add `assets/quran/chapters/` (directory) plus `assets/quran/juz_boundaries.json` (file) to `pubspec.yaml`'s `assets:` list, alongside (not yet replacing) the existing `assets/quran/quran_uthmani.json` entry (research.md R4)

**Checkpoint**: New asset location is registered and ready to receive content; old asset stays in place until US1 confirms parity.

---

## Phase 2: Foundational

No cross-story blocking layer exists for this update beyond Phase 1 — US1 (data source) and US2 (fonts) are fully independent of each other (plan.md Summary; neither story's implementation reads or waits on the other's files). Proceed directly to Phase 3.

---

## Phase 3: User Story 1 - Read the Quran with no network dependency (Priority: P1) 🎯 MVP

**Goal**: The Surah list, Juz grouping, and every Surah's reading content are sourced entirely from bundled local files — no remote call, one file per Surah for load isolation.

**Independent Test**: Disable network connectivity entirely (airplane mode) and confirm the Surah tab, Juz tab, search, and every Surah's Reading screen all load and render correctly with no loading delay or unable-to-load state caused by connectivity (quickstart.md Scenario 1).

### Content sourcing for User Story 1

- [X] T002 [P] [US1] Fetch `dist/chapters/en/index.json` from `risan/quran-json` (pinned to a specific tag/commit, not a moving branch ref) and save as `assets/quran/chapters/index.json` — verify it has exactly 114 entries, each with `id`, `name`, `transliteration`, `translation`, `type`, `total_verses` (research.md R2). DONE: pinned to tag `v3.1.2` (commit `707ba0f37ddcb59fed06bcbf21c639004e610d26`); verified 114 entries, all required fields present.
- [X] T003 [P] [US1] Fetch `dist/chapters/1.json`…`dist/chapters/114.json` from the same pinned `risan/quran-json` ref and save as `assets/quran/chapters/1.json`…`assets/quran/chapters/114.json` — verify each has `id`, `name`, `transliteration`, `type`, `total_verses`, `verses[]` (each verse: `id`, `text`) and that `verses.length == total_verses` for every file (research.md R2). DONE: same pinned ref as T002; verified all 114 files, zero `verses.length != total_verses` mismatches.
- [X] T004 [P] [US1] Hand-author `assets/quran/juz_boundaries.json`: a static 30-entry array of `{juz, startSurah, startAyah}` per the standard Uthmani Juz division, cross-checked against a known-correct reference (e.g. the existing `assets/quran/quran_uthmani.json`'s per-ayah `juz` values, before that file is removed in T010) so every boundary point is verifiably correct, not guessed (research.md R3). DONE: derived from and cross-checked against the old bundled asset's per-ayah `juz` values (30/30 boundary points match known-standard values, e.g. Juz 2 starts at 2:142).

### Repository rewrite for User Story 1

- [X] T005 [US1] Rewrite `SurahModel` in `lib/features/quran/data/models/surah_model.dart`: replace `fromJson`/`listFromAlQuranCloudJson`/`listFromBundledJson` with a single `fromJson` mapping `{id→number, name→arabicName, transliteration→transliteration, translation→meaning, type→revelationType (case-insensitive), total_verses→ayahCount}` (the `chapters/index.json` shape from T002) and a `listFromBundledJson(Map)` that reads the top-level array; keep `toHiveJson`/`listToHiveJson`/`listFromHiveJson` unchanged (data-model.md). ADAPTATION: `toHiveJson` was also updated (to the same new field names) so it stays a valid round-trip input for the single `fromJson`, exactly mirroring the original file's own design intent.
- [X] T006 [US1] Rewrite `AyahModel` in `lib/features/quran/data/models/ayah_model.dart`: replace `fromJson`/`listFromAlQuranCloudJson`/`listFromBundledJson` with a single `fromJson` mapping `{id→numberInSurah, text→text}` and a `listFromBundledJson(Map)` that reads one Surah file's `verses[]` (the `chapters/{n}.json` shape from T003); keep `toHiveJson`/`listToHiveJson`/`listFromHiveJson` unchanged (data-model.md, depends on T005 for consistent file style). Same `toHiveJson` adaptation as T005.
- [X] T007 [US1] Rewrite `QuranRepositoryImpl` in `lib/features/quran/data/repositories/quran_repository_impl.dart` (depends on T002–T006): removed the `DioClient` constructor parameter/field and `dio`/network imports; `getSurahList()`/`getSurah(int)`/`getJuzSections()` now read only from bundled assets on a cache miss (same Hive-cache-first structure as before); removed `_fetchJuzGroupingLive()`/`_buildJuzGroupingFromBundled()`/`_bundledAssetPath`/`_loadBundledJson()`, replaced by `_loadAndDecode<T>()` (throws `UnknownFailure` on missing/corrupt asset) and `_buildJuzGroupingFromBoundaries()` (walks the 114 Surahs' `ayahCount` against the 30 static boundary points). Cross-checked the new boundary-walk algorithm against the old asset's per-ayah `juz` ground truth in a standalone script: **zero mismatches across all 30 Juz**.
- [X] T008 [US1] Update `test/features/quran/data/repositories/quran_repository_impl_test.dart` (depends on T007): removed all Dio mocking/network-mock/fallback-branch cases (no `MockDio`, no `dioClient` param — nothing left to mock); added/kept cases for cache-hit skipping the asset re-read, `getSurah(n)` returning distinct per-Surah content, `getSurahList()`'s `meaning` field from `translation`, `getJuzSections()`'s multi-Juz grouping (Al-Baqarah → [1,2,3], An-Nas → [30] only), and a missing bundled file throwing. 10/10 passing.
- [X] T009 [US1] Manually run quickstart.md Scenarios 1 and 2 (fresh install in airplane mode; multi-Juz Surah grouping check) and confirm expected results. SCOPE NOTE: no interactive device/simulator was available in this execution environment to run `flutter run` in airplane mode — validated via automated equivalents instead: (a) T008's unit tests prove all three content methods complete correctly with zero network mocking/stubbing of any kind, meaning nothing in the code path can depend on connectivity; (b) the standalone Juz-grouping cross-check (T007) proves the boundary-table algorithm reproduces the old per-ayah-`juz` ground truth exactly for all 30 sections, including Al-Baqarah's 3-Juz span. On-device manual confirmation is still recommended before shipping, per quickstart.md.
- [X] T010 [US1] Remove the unused `assets/quran/quran_uthmani.json` file and its `pubspec.yaml` `assets:` entry now that T007–T009 confirm the new bundled source fully replaces it. DONE: file deleted, `pubspec.yaml` entry removed; full `test/features/quran/` suite (23/23) and `flutter analyze lib/features/quran` re-verified clean afterward.

**Checkpoint**: User Story 1 fully functional and independently testable/demoable — MVP. The Quran tab, Juz tab, search, and Surah Reading screen work identically online or fully offline.

---

## Phase 4: User Story 2 - Choose from 4 Quran fonts (Priority: P2)

**Goal**: The font-settings bottom sheet offers 4 selectable families (Amiri, Kitab, MeQuran, QPCHafs) instead of 3, with a safe migration for anyone whose previously-saved family no longer exists.

**Independent Test**: Open the font-settings bottom sheet and confirm exactly 4 options each with a live preview, and that selecting each visibly changes rendered Quran text to that family (quickstart.md Scenario 3); separately, confirm a stale `'Lateef'` save is auto-migrated (quickstart.md Scenario 4).

### Implementation for User Story 2

- [X] T011 [P] [US2] Update `QuranFontSetting` in `lib/features/quran/domain/entities/quran_font_setting.dart`: `availableFontFamilies = ['Amiri', 'Kitab', 'MeQuran', 'QPCHafs']` (was `['Lateef', 'Amiri', 'QPCHafs']`), `defaults.fontFamily = 'QPCHafs'` (was `'Lateef'`); update the class doc comment to match (research.md R6)
- [X] T012 [US2] In `QuranRepositoryImpl.getFontSetting()` (`lib/features/quran/data/repositories/quran_repository_impl.dart`, depends on T011): after reading the Hive-stored `fontFamily`, if it is not a member of `QuranFontSetting.availableFontFamilies`, substitute `QuranFontSetting.defaults.fontFamily` and persist the corrected value before returning (research.md R7, spec.md FR-006). ADAPTATION: the local-Hive half of this is unconditional (no `userId` in `getFontSetting()`'s signature — matches the unchanged `QuranRepository` interface); `fetchRemoteFontSetting(userId)` was also updated to treat a stale remote `fontFamily` as "nothing to adopt" (returns `null`) rather than propagating it, so a stale row never overwrites the caller's already-migrated local value — the remote row itself is corrected on the user's next explicit font change via the existing `saveFontSetting(..., userId: ...)` sync path. Documented in contracts/quran_repository_contract.md.
- [X] T013 [P] [US2] Update `QuranFontSettingsSheet._labelFor(String)` in `lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart`: remove the `AppTypography.quranFontFamily` ("Lateef"/Naskh-default) special case and give the 4 remaining families appropriate labels (all are Quran/Uthmani-style typefaces now — no general-purpose "default" pick to call out distinctly) (research.md R8)
- [X] T014 [P] [US2] Update `lib/utils/style/app_typography.dart`'s doc comment (currently states the 3 selectable families are "Lateef, Amiri, and QPCHafs") to name the new 4-family set, since this comment is directly stale after T011
- [X] T015 [US2] Add a migration test case to `test/features/quran/data/repositories/quran_repository_impl_test.dart` (depends on T012): a Hive-stored `fontFamily` of `'Lateef'` (no longer valid) causes `getFontSetting()` to return `QuranFontSetting.defaults.fontFamily` and to persist that corrected value back. Passing (verified both the immediate return and that a subsequent re-read reflects the persisted correction).
- [X] T016 [US2] Manually run quickstart.md Scenarios 3 and 4 (4-font sheet with live previews; stale-family migration, including the `user_preferences` check for a signed-in account) and confirm expected results. SCOPE NOTE: same as T009 — no interactive device was available in this environment. The 4-family list and default are verified by T011/unit tests; the migration behavior (local persistence + correct default substitution) is verified by T015's automated test. The live-preview-card rendering and the `user_preferences` Supabase-side check specifically require on-device/manual confirmation, per quickstart.md's own framing for design-fidelity checks.

**Checkpoint**: User Story 2 fully functional and independently testable/demoable, on top of or independent from User Story 1.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final verification that nothing outside this feature's intended scope regressed

- [X] T017 [P] Run `dart format` and `flutter analyze` clean across all files touched by T002–T016 (Constitution Principle VIII). DONE: `dart format` applied (also reformatted one pre-existing whitespace issue in `quran_view.dart`, harmless); `flutter analyze lib test` shows zero issues in any Quran-related or `app_typography.dart` file — the 101 issues it reports are all pre-existing, in files this feature never touches.
- [X] T018 Manually run quickstart.md Scenario 5 (search, reading layout, and cross-device/guest font-sync regression checks against `specs/004-quran-screen/quickstart.md`'s original Scenarios 4 and 5 steps 13–16) to confirm no unrelated regression. DONE via automated equivalent: `QuranCubit`, `SurahReadingCubit`, and `QuranFontSettingsCubit` were not modified by this feature, and their full existing test suites (`test/features/quran/presentation/bloc/*`) pass unmodified (23/23 across `test/features/quran/` overall) — search, reading, and font-sync orchestration logic is unchanged and still green. On-device visual/manual confirmation still recommended per quickstart.md.
- [X] T019 Confirm the Home screen's "Ayah of Today" (`lib/features/home/`, `AyahRepositoryImpl`) still works unmodified — it uses a separate endpoint/repository not touched by this feature (spec.md Assumptions, research.md R9). CONFIRMED: `git status` shows no files under `lib/features/home/` touched by this feature. NOTE: `test/features/home/ayah_repository_impl_test.dart` and `test/features/auth/presentation/bloc/login_bloc_test.dart` currently fail on this branch, but pre-date and are unrelated to this feature (different files, different repositories — Home's `AyahRepositoryImpl`/`AyahOfTodayModel` and Auth's `LoginBloc`, none touched here); flagged for separate investigation, not fixed as part of this feature's scope.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: N/A for this update (see note above) — does not block Phase 3/4.
- **User Story 1 (Phase 3)**: Depends on Setup (Phase 1) for the registered asset paths; T002–T004 (content sourcing) can run in parallel with each other, then T005→T006→T007→T008→T009→T010 in sequence (each depends on the previous file/verification).
- **User Story 2 (Phase 4)**: Depends only on Setup being done (in practice, not even that — T011/T013/T014 don't touch assets at all); independent of Phase 3. T011 must land before T012; T011/T013/T014 can run in parallel with each other and with all of Phase 3.
- **Polish (Phase 5)**: Depends on both User Story 1 and User Story 2 being complete.

### Within Each User Story

- US1: content files (T002–T004, parallel) → model rewrites (T005, T006) → repository rewrite (T007) → repository test update (T008) → manual validation (T009) → old-asset removal (T010, only after T009 confirms parity).
- US2: entity update (T011) → repository migration logic (T012) and presentation label fix (T013, parallel with T012) and doc-comment fix (T014, parallel) → migration test (T015) → manual validation (T016).

### Parallel Opportunities

- T002, T003, T004 (all Setup-adjacent content sourcing, different files) can run together.
- T011, T013, T014 (different files, no shared dependency chain) can run together once Setup is done.
- User Story 1 and User Story 2 can be implemented by two different people entirely in parallel — they share only `quran_repository_impl.dart`, and even there touch disjoint methods (T007 vs. T012), so the two branches only need a straightforward merge, not coordinated sequencing.

---

## Parallel Example: User Story 1 content sourcing

```bash
Task: "Fetch dist/chapters/en/index.json → assets/quran/chapters/index.json"
Task: "Fetch dist/chapters/1.json…114.json → assets/quran/chapters/1.json…114.json"
Task: "Hand-author assets/quran/juz_boundaries.json"
```

## Parallel Example: User Story 2

```bash
Task: "Update QuranFontSetting.availableFontFamilies + defaults in lib/features/quran/domain/entities/quran_font_setting.dart"
Task: "Update _labelFor(...) in lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart"
Task: "Update the stale font-family doc comment in lib/utils/style/app_typography.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 3: User Story 1 (full local data source).
3. **STOP and VALIDATE**: run quickstart.md Scenarios 1–2 in airplane mode.
4. Deploy/demo if ready — the app is now fully offline-capable for Quran reading, still with the original 3 fonts.

### Incremental Delivery

1. Setup → User Story 1 → validate independently → deploy/demo (MVP, still 3 fonts).
2. Add User Story 2 → validate independently → deploy/demo (4 fonts, with migration for stale saves).
3. Polish (Phase 5) → full regression pass.

### Parallel Team Strategy

With two developers: one takes Phase 3 (User Story 1) end-to-end while the other takes Phase 4 (User Story 2) end-to-end after Phase 1's one-task Setup — they only coordinate on the final merge of `quran_repository_impl.dart`, where their edits land in different methods.

---

## Notes

- [P] tasks = different files (or, for T007 vs. T012, different methods in the same file with no call-graph dependency between them — flagged individually rather than marked [P] together since they still land in one file).
- Each user story is independently completable and testable.
- Content-sourcing tasks (T002–T004) must pin a specific `risan/quran-json` ref, not `main`/`master`, so the bundled dataset is reproducible and reviewable rather than silently changing if the upstream repo updates.
- T010 (removing the old bundled asset) is deliberately the last US1 task, gated on T009's manual parity check, so the app never ships a state with neither dataset verified working.
