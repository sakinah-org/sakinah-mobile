---

description: "Task list for Settings Screen (specs/006-settings-screen)"
---

# Tasks: Settings Screen

**Input**: Design documents from `/specs/006-settings-screen/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Included for new/extended business logic only (`SettingsCubit` extensions, `SessionCubit.logout()`, `QiblaCompassCubit`/`QiblaRepository`), per Constitution Principle VIII ("new or changed business logic SHOULD ship with a unit test"; UI-only widget/page work is not required to). Not TDD-ordered (tests are not required to fail first) — write them alongside or immediately after the corresponding Cubit/repository task.

**Organization**: Tasks are grouped by user story (spec.md priorities) so each story is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Maps the task to spec.md's US1–US5
- File paths are exact, relative to the repository root

## Path Conventions

Single Flutter project — `lib/`, `test/`, `assets/lang/` at the repository root, per plan.md's Project Structure.

---

## Phase 1: Setup

**Purpose**: New dependency this feature needs before any Qibla work can compile.

- [ ] T001 Add `flutter_qiblah: ^3.2.0` to `pubspec.yaml` dependencies (research.md R6) and run `flutter pub get`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The Settings screen must exist and be reachable before any user story can be demonstrated — every story in this feature renders on or is opened from it.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T002 Create `SettingsPage` scaffold — `Scaffold` with an app bar titled via `translator.word(TranslationKeys.settingsScreenTitle)`, RTL/LTR-aware, empty scrollable body for now — in `lib/features/settings/presentation/pages/settings_page.dart`
- [ ] T003 Wire `SettingsPage` into `MainPage`'s third tab, replacing the placeholder `Container()`, in `lib/features/main/ui/pages/main_page.dart` (depends on T002)
- [ ] T004 [P] Add `settingsScreenTitle` key to `lib/configurations/app_translation_keys.dart` and both `assets/lang/en.json` / `assets/lang/ar.json`

**Checkpoint**: Opening the Settings tab shows an empty titled screen. User story work can now begin.

---

## Phase 3: User Story 1 - See My Account Status at a Glance (Priority: P1) 🎯 MVP

**Goal**: The account section shows a guest prompt or the authenticated user's name/email, and updates live on auth-state change — no new business logic, purely reads the existing `SessionCubit` (research.md R2).

**Independent Test**: Open Settings as a guest → guest prompt shows. Sign in, reopen Settings → name/email show instead, without leaving/re-entering the screen.

### Implementation for User Story 1

- [ ] T005 [P] [US1] Create `SettingsGuestPromptCard` widget (teal gradient hero card: person icon, "Browsing as guest" title, sync-benefit subtitle, primary "Log in" CTA that does `Navigator.pushNamed(context, AppRoutes.login)`) matching design §08 GUEST figures, in `lib/features/settings/presentation/widgets/settings_guest_prompt_card.dart`
- [ ] T006 [P] [US1] Create `SettingsAuthenticatedProfileCard` widget (initial-letter avatar circle, name, email, "sync active" badge) matching design §08 LOGGED IN figures, in `lib/features/settings/presentation/widgets/settings_authenticated_profile_card.dart`
- [ ] T007 [US1] Wire the account section into `SettingsPage`: `BlocBuilder<SessionCubit, AppStates>` switching between `SettingsAuthenticatedProfileCard` (when `SessionCubit.instance.isLoggedIn`) and `SettingsGuestPromptCard` (otherwise), in `lib/features/settings/presentation/pages/settings_page.dart` (depends on T002, T005, T006)
- [ ] T008 [US1] Add guest/authenticated account-section translation keys (guest title/subtitle/CTA, sync-active badge label) to `lib/configurations/app_translation_keys.dart` and both `assets/lang/{en,ar}.json`

**Checkpoint**: User Story 1 fully functional and independently testable (per quickstart.md US1).

---

## Phase 4: User Story 2 - Reach Prayer Times, Qibla Compass, and Language Settings from One Place (Priority: P1) 🎯 MVP

**Goal**: A single options list routes to Prayer Times, opens the Qibla Compass screen, and opens the language bottom sheet — for guests and authenticated users alike; Logout only appears when authenticated. Destination screens/sheets may be minimal placeholders here (fleshed out by US3/US4), per spec.md's own independent-test note.

**Independent Test**: From Settings, tap each option and confirm it opens the correct destination; confirm Logout is hidden for guests and shown for authenticated users.

### Implementation for User Story 2

- [ ] T009 [P] [US2] Create a minimal `QiblaCompassPage` placeholder (app bar with back button + title only, empty body) in `lib/features/qibla/presentation/pages/qibla_compass_page.dart` — fleshed out fully in US4
- [ ] T010 [P] [US2] Create a minimal `LanguageBottomSheet` placeholder — `static Future<void> show(BuildContext context)` opening a `showModalBottomSheet` with just a drag handle, title, and close button, following the `QuranFontSettingsSheet.show` pattern (`lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart:24`) — in `lib/features/settings/presentation/widgets/language_bottom_sheet.dart` — fleshed out fully in US3
- [ ] T011 [P] [US2] Create reusable `SettingsOptionTile` widget (leading icon in a tinted rounded square, label, optional trailing value text, trailing chevron, `onTap`) matching design §08 row treatment, in `lib/features/settings/presentation/widgets/settings_option_tile.dart`
- [ ] T012 [US2] Add `AppRoutes.qiblaCompass = '/qibla-compass'` to `lib/navigation/app_routes.dart` and a matching `case` returning `const QiblaCompassPage()` in `lib/navigation/route_generator.dart` (depends on T009)
- [ ] T013 [US2] Build the options list into `SettingsPage`: `SettingsOptionTile` rows for Prayer Times (`Navigator.pushNamed(context, AppRoutes.prayers)`), Qibla Compass (`Navigator.pushNamed(context, AppRoutes.qiblaCompass)`), Change Language (`LanguageBottomSheet.show(context)`), and — only when `SessionCubit.instance.isLoggedIn` — a visually-separated Logout row (`onTap` left as a no-op stub; wired for real in US5), in `lib/features/settings/presentation/pages/settings_page.dart` (depends on T007, T010, T011, T012)
- [ ] T014 [US2] Add options-list translation keys (Prayer Times / Qibla Compass / Change Language / Logout row labels, current-language trailing value) to `lib/configurations/app_translation_keys.dart` and both `assets/lang/{en,ar}.json`

**Checkpoint**: User Stories 1 AND 2 both work independently — the full Settings screen is navigable (per quickstart.md US2).

---

## Phase 5: User Story 3 - Switch the App Language (Priority: P2)

**Goal**: The language bottom sheet offers Arabic/English, selecting one applies the locale and RTL/LTR layout immediately and persists it across restarts.

**Independent Test**: Open the sheet, pick the inactive language, confirm immediate app-wide language + direction change with no restart, and that it survives a relaunch.

### Tests for User Story 3

- [ ] T015 [P] [US3] `bloc_test`/`mocktail` unit test for `SettingsCubit.setLocale()` (persists + emits, idempotent when re-selecting the active language) and `loadPersistedSettings()` (hydrates from a fake `SharedPrefHandler`, falls back to the default when nothing is persisted) in `test/shared/bloc/settings_cubit_test.dart`

### Implementation for User Story 3

- [ ] T016 [US3] Extend `SettingsCubit` with `Future<void> setLocale(Locale locale)` and `Future<void> loadPersistedSettings()` per `contracts/settings_cubit_contract.md`, in `lib/shared/bloc/settings_cubit.dart` (depends on T017)
- [ ] T017 [P] [US3] Add `appLocale` key to `lib/configurations/app_persistence_data_keys.dart`
- [ ] T018 [US3] Call `await SettingsCubit.instance.loadPersistedSettings();` in `main()`, after `SharedPrefHandler.init()` and before `runApp(...)`, in `lib/main.dart` (depends on T016)
- [ ] T019 [US3] Flesh out `LanguageBottomSheet` (T010 placeholder) into the full design: footnote copy, two rows (Arabic/English — native name leading, other language's gloss underneath), brand-border + check circle on the active row vs. plain border + empty circle on the other, each row calling `context.read<SettingsCubit>().setLocale(...)` and closing the sheet, matching design §06, in `lib/features/settings/presentation/widgets/language_bottom_sheet.dart` (depends on T016)
- [ ] T020 [US3] Add language-sheet translation keys (sheet title, relaunch/apply footnote, Arabic/English native names + glosses) to `lib/configurations/app_translation_keys.dart` and both `assets/lang/{en,ar}.json`

**Checkpoint**: User Stories 1–3 all work independently (per quickstart.md US3).

---

## Phase 6: User Story 4 - Find the Qibla Direction (Priority: P2)

**Goal**: A live rotating compass toward the Kaaba, a calibration prompt on low sensor accuracy, and a static-degree fallback with no magnetometer — matching design §10.

**Independent Test**: Open Qibla Compass with a working sensor + location → live rotating dial. Force low accuracy → calibration prompt. No magnetometer → static degree + message. No location → explanation + retry.

### Tests for User Story 4

- [ ] T021 [P] [US4] `bloc_test`/`mocktail` unit test for `QiblaCompassCubit` (`load()`/`retry()` transitions into Live/Static/LocationRequired against a fake `QiblaRepository`, per `contracts/qibla_repository_and_cubit_contract.md`) in `test/features/qibla/qibla_compass_cubit_test.dart`

### Implementation for User Story 4

- [ ] T022 [P] [US4] Create `QiblaReading`/`QiblaLiveReading`/`QiblaStaticReading`/`CompassAccuracy` entities per data-model.md §3, in `lib/features/qibla/domain/entities/qibla_reading.dart`
- [ ] T023 [P] [US4] Define the `QiblaRepository` abstract interface per `contracts/qibla_repository_and_cubit_contract.md`, in `lib/features/qibla/domain/repositories/qibla_repository.dart`
- [ ] T024 [US4] Implement `QiblaRepositoryImpl` — `getBearing()`/`hasCompassSensor()`/`watchLiveBearing()` wrapping `flutter_qiblah` + `FlutterCompass.events` (accuracy) + the existing `LocationHandler`/`PermissionHandler` + the great-circle static-bearing fallback (research.md R6–R8) — in `lib/features/qibla/data/repositories/qibla_repository_impl.dart` (depends on T001, T022, T023)
- [ ] T025 [US4] Create `QiblaCompassState` typed states (`QiblaInitialState`, `QiblaLoadingState`, `QiblaLiveState`, `QiblaStaticState`, `QiblaLocationRequiredState`) per data-model.md §4, in `lib/features/qibla/presentation/bloc/qibla_compass_state.dart` (depends on T022)
- [ ] T026 [US4] Implement `QiblaCompassCubit` (`load()`, `retry()`) per `contracts/qibla_repository_and_cubit_contract.md`, in `lib/features/qibla/presentation/bloc/qibla_compass_cubit.dart` (depends on T024, T025)
- [ ] T027 [P] [US4] Create `QiblaCompassDial` widget (circular dial, N/S/E/W labels, dashed inner ring, rotating needle + Kaaba icon toward bearing, degree text, direction/distance captions) matching design §10, in `lib/features/qibla/presentation/widgets/qibla_compass_dial.dart`
- [ ] T028 [P] [US4] Create `QiblaCalibrationBanner` widget (figure-eight calibration guidance pill, shown only while accuracy is low) in `lib/features/qibla/presentation/widgets/qibla_calibration_banner.dart`
- [ ] T029 [P] [US4] Create `QiblaStaticBearingView` widget (static degree value + explanatory "no compass sensor" message) in `lib/features/qibla/presentation/widgets/qibla_static_bearing_view.dart`
- [ ] T030 [P] [US4] Create `QiblaLocationRequiredView` widget (explanation + grant/retry action calling the cubit's `retry()`) in `lib/features/qibla/presentation/widgets/qibla_location_required_view.dart`
- [ ] T031 [US4] Flesh out `QiblaCompassPage` (T009 placeholder) into the full page: `BlocProvider(create: (_) => QiblaCompassCubit(...)..load())` + `BlocBuilder<QiblaCompassCubit, QiblaCompassState>` switching between `QiblaCompassDial` (+ `QiblaCalibrationBanner` when accuracy is low), `QiblaStaticBearingView`, and `QiblaLocationRequiredView`, in `lib/features/qibla/presentation/pages/qibla_compass_page.dart` (depends on T026, T027, T028, T029, T030)
- [ ] T032 [US4] Add Qibla translation keys (screen title, "Qibla direction" + compass-point label, distance-to-Mecca label, "point the top of your phone" hint, calibration title/message, no-sensor message, location-required title/message/CTA) to `lib/configurations/app_translation_keys.dart` and both `assets/lang/{en,ar}.json`

**Checkpoint**: User Stories 1–4 all work independently (per quickstart.md US4 — physical device required for live-sensor checks).

---

## Phase 7: User Story 5 - Log Out Without Losing Local Functionality (Priority: P3)

**Goal**: Logout asks for confirmation, then returns the app to guest mode with all local preferences (language, etc.) untouched and guest features fully working.

**Independent Test**: While authenticated, tap Logout → confirm → account section reverts to guest, Logout row disappears, previously-set language is unchanged, Prayer Times/Qibla Compass still work.

### Tests for User Story 5

- [ ] T033 [P] [US5] `bloc_test`/`mocktail` unit test for `SessionCubit.logout()` (clears only the four session keys, leaves other `SharedPrefHandler` keys untouched, emits `LoadedState(null)`) per `contracts/session_cubit_logout_contract.md`, in `test/shared/bloc/session_cubit_logout_test.dart`

### Implementation for User Story 5

- [ ] T034 [US5] Implement `SessionCubit.logout()` per `contracts/session_cubit_logout_contract.md`, in `lib/shared/bloc/session_cubit.dart` (depends on T033)
- [ ] T035 [P] [US5] Create `SettingsLogoutConfirmationDialog` widget (`AlertDialog` with Cancel + destructive-styled Logout actions) in `lib/features/settings/presentation/widgets/settings_logout_confirmation_dialog.dart`
- [ ] T036 [US5] Wire the Settings options list's Logout row `onTap` (T013 stub) to `showDialog` the confirmation dialog and call `SessionCubit.instance.logout()` on confirm, in `lib/features/settings/presentation/pages/settings_page.dart` (depends on T013, T034, T035)
- [ ] T037 [US5] Add logout-confirmation translation keys (dialog title/message, confirm/cancel labels) to `lib/configurations/app_translation_keys.dart` and both `assets/lang/{en,ar}.json`

**Checkpoint**: All 5 user stories independently functional — feature complete (per quickstart.md US5).

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T038 [P] Run `dart format lib test` and `flutter analyze`, fix any warnings across all files touched by this feature
- [ ] T039 [P] Visually verify every new/changed screen (Settings guest + authenticated, options list, language sheet, Qibla Compass's 4 states) in both light and dark theme and both RTL (Arabic) and LTR (English) against the imported design mock (§06/§08/§10)
- [ ] T040 Run through `quickstart.md` end-to-end — Cross-cutting section plus all 5 user-story sections — on a physical device (required for the Qibla live-sensor paths)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3–7)**: All depend on Foundational; within this feature they build on each other in priority order (US1, US2 → MVP; then US3, US4; then US5) because US2 introduces the placeholders (`QiblaCompassPage`, `LanguageBottomSheet`, the Logout row) that US3/US4/US5 flesh out — see the per-task `depends on` notes above for the exact edges
- **Polish (Phase 8)**: Depends on all 5 user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational
- **US2 (P1)**: Depends only on Foundational (independent of US1's cards, but both land on the same `SettingsPage`)
- **US3 (P2)**: Depends on US2's `LanguageBottomSheet` placeholder (T010) and route wiring
- **US4 (P2)**: Depends on US2's `QiblaCompassPage` placeholder (T009) and route wiring (T012)
- **US5 (P3)**: Depends on US2's Logout row stub (T013)

### Parallel Opportunities

- Within Phase 2: T004 can run alongside T002/T003 (different files)
- Within US1: T005, T006 in parallel; T007 waits on both
- Within US2: T009, T010, T011 in parallel; T012 waits on T009; T013 waits on T007/T010/T011/T012
- Within US3: T015, T017 in parallel; T016 waits on T017; T018/T019 wait on T016
- Within US4: T021, T022, T023 in parallel; T024 waits on T022/T023; T025 waits on T022; T026 waits on T024/T025; T027–T030 in parallel (independent widget files); T031 waits on T026–T030
- Within US5: T033, T035 in parallel; T034 waits on T033; T036 waits on T034/T035
- Within Polish: T038, T039 in parallel; T040 last

---

## Parallel Example: User Story 4 (largest story)

```bash
# Tests + domain layer together:
Task: "bloc_test for QiblaCompassCubit in test/features/qibla/qibla_compass_cubit_test.dart"
Task: "QiblaReading entities in lib/features/qibla/domain/entities/qibla_reading.dart"
Task: "QiblaRepository interface in lib/features/qibla/domain/repositories/qibla_repository.dart"

# Once QiblaCompassCubit exists, all 4 view-state widgets together:
Task: "QiblaCompassDial widget in lib/features/qibla/presentation/widgets/qibla_compass_dial.dart"
Task: "QiblaCalibrationBanner widget in lib/features/qibla/presentation/widgets/qibla_calibration_banner.dart"
Task: "QiblaStaticBearingView widget in lib/features/qibla/presentation/widgets/qibla_static_bearing_view.dart"
Task: "QiblaLocationRequiredView widget in lib/features/qibla/presentation/widgets/qibla_location_required_view.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3 (US1) + Phase 4 (US2)
4. **STOP and VALIDATE**: quickstart.md US1 + US2 sections
5. This is a fully navigable Settings screen (with Qibla/Language as placeholders) — demoable MVP

### Incremental Delivery

1. Setup + Foundational → empty Settings tab reachable
2. US1 + US2 → MVP: account section + full navigation (placeholders for Qibla/Language)
3. US3 → language switching fully real
4. US4 → Qibla Compass fully real
5. US5 → logout fully real
6. Polish → format/analyze, visual parity pass, full quickstart run

---

## Notes

- [P] tasks touch different files and have no incomplete dependency
- Every translation-key task touches the same two files (`app_translation_keys.dart` + both `assets/lang/*.json`) as other stories' translation-key tasks — never marked [P], to avoid merge conflicts if run concurrently
- `flutter_qiblah` does not work on the iOS Simulator — US4's manual verification (T040) needs a physical device
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
