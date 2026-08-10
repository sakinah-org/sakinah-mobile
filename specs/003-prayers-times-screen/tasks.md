---

description: "Task list template for feature implementation"
---

# Tasks: Prayers Times Screen

**Input**: Design documents from `/specs/003-prayers-times-screen/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included for new business logic (Cubit + repository) per Constitution Principle VIII ("New or changed business logic... SHOULD ship with a unit test") and quickstart.md's automated-checks list. No UI/widget tests are included (not required by the constitution).

**Organization**: Tasks are grouped by user story (spec.md P1/P2/P3) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are exact and repo-relative

## Path Conventions

Single Flutter app — `lib/` and `test/` at repository root, per plan.md's Project Structure. No web/mobile-API split.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: New dependencies and config-layer additions needed before any feature code is written

- [X] T001 [P] Add `flutter_local_notifications`, `timezone`, and `geocoding` to `pubspec.yaml` dependencies; run `flutter pub get` (research.md R1, R3)
- [X] T002 [P] Add `prayerNotificationSettings` Hive key to `lib/configurations/app_persistence_data_keys.dart`, under a new `// Prayer Notification Settings (lib/features/prayers/)` header (research.md R5)
- [X] T003 [P] Add `prayerNotificationSettingsTable` constant (`'prayer_notification_settings'`) to `lib/configurations/app_end_points.dart` (research.md R6)
- [X] T004 [P] Add Prayers-screen string keys to `lib/configurations/app_translation_keys.dart` and their English/Arabic values to `assets/lang/en.json` / `assets/lang/ar.json`: location card labels, the fixed "10 minutes before" caption, the all-off banner message, the notification-denied help card text + "Enable" button, the notification-permanently-denied card text + "Enable" button, the "configure a location" guidance text (FR-001–003, FR-008, FR-011, FR-013, FR-014)
- [X] T005 [P] ~~Add an alert/warning icon key~~ — DEVIATION: reused the existing `AppIcons.notifications` (bell) key instead of authoring a new SVG glyph, since no pixel-accurate design asset was available this session (no Figma/design MCP import occurred) — avoids guessing at icon geometry (Constitution Principle IV: existing registered asset, no ad hoc path)
- [X] T006 Configure Android (`android/app/src/main/AndroidManifest.xml`: added `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`) for `flutter_local_notifications`; iOS needs no `Info.plist`/`AppDelegate` change — the system notification prompt requires no usage-description key, and `GeneratedPluginRegistrant` already auto-registers the plugin (research.md R3)

**Checkpoint**: New packages installed and configured; new config/asset keys exist and are ready to consume.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: A working, routed Prayers screen shell that later story phases add content to

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 Replace the placeholder body of `lib/features/prayers/presentation/pages/prayers_page.dart` with a `Scaffold` that reuses the existing `PrayerTimesCubit.instance` (same `BlocProvider.value` + `loadPrayerTimes()`-on-first-build pattern `HomePage` already uses), rendering a temporary empty body. The existing route (`AppRoutes.prayers` → `PrayersPage` in `lib/navigation/route_generator.dart`) is unchanged (research.md R8)

**Checkpoint**: `/prayers` route renders a real (if empty) screen backed by live prayer-times state — ready for story work.

---

## Phase 3: User Story 1 - See today's prayer times for my location (Priority: P1) 🎯 MVP

**Goal**: Location card (city, country, calculation method, Hijri date) plus all five prayers' names and times, with the same offline-fallback / unable-to-load / no-location states the shared module already provides.

**Independent Test**: Open the Prayers screen with a resolved location and confirm the location card and all five prayer times render correctly; confirm offline fallback and "unable to load" states appear when applicable — independent of any toggle behavior.

### Implementation for User Story 1

- [X] T008 [US1] Add `resolveDisplayLocation(PrayerLocation location)` to `lib/shared/prayer_times/domain/repositories/prayer_times_repository.dart` (abstract method) and implement it in `lib/shared/prayer_times/data/repositories/prayer_times_repository_impl.dart` using the `geocoding` package's `placemarkFromCoordinates`, caching the resolved `{city, country}` alongside the existing lat/lng Hive entry so it isn't re-geocoded every screen open (research.md R1). ADAPTATION: added `lib/handlers/geocoding_handler.dart` (mirroring `LocationHandler`'s wrapper shape) as a constructor-DI seam, since `geocoding` v5's API is an instantiable `Geocoding` class, not free functions — needed for T009's `mocktail` test seam
- [X] T009 [P] [US1] Unit test `resolveDisplayLocation()` in `test/shared/prayer_times/prayer_times_repository_impl_test.dart` (cache hit, cache miss → geocode + persist, geocode failure → `null`), mirroring the file's existing `mocktail` DI-seam pattern (depends on T008) — 4 new tests, all passing (`flutter test` 11/11 green)
- [X] T010 [P] [US1] Create `PrayerLocationCard` widget in `lib/features/prayers/presentation/widgets/prayer_location_card.dart`: city/country via `resolveDisplayLocation()`, calculation method label via `PrayerTimesRepository.getStoredCalculationMethod()`, and Hijri date via the existing `now.hijriDateLabel(locale)` extension (`lib/toolkit/extensions/date_time_extensions.dart`) rendered independently of the rest of the card so it degrades gracefully if unavailable (FR-001, acceptance scenario 5) (depends on T008). ADAPTATION: added `PrayerTimesCubit.loadLocationCardInfo()` (with 2 new cubit tests) as the access path, since the cubit's existing public API had no way to expose location/method to a widget without breaking its own "only caller of PrayerTimesRepository" rule
- [X] T011 [P] [US1] Create a display-only `PrayerReminderTile` widget (name + time only, no toggle yet) in `lib/features/prayers/presentation/widgets/prayer_reminder_tile.dart`, reusing `prayerCodeLabel`/`prayerCodeIcon` from `lib/shared/prayer_times/presentation/prayer_code_presentation.dart`
- [X] T012 [US1] Wire `PrayersPage`/`PrayersView` to render `PrayerLocationCard` + five `PrayerReminderTile`s driven by `BlocBuilder<PrayerTimesCubit, PrayerTimesState>`, reusing the same state-branch structure `PrayerTimesSection` already uses on Home (loading skeleton, loaded, location-required, unavailable — FR-009, FR-010, FR-011) (depends on T007, T010, T011). ADAPTATION: promoted `PrayerTimesUnavailableView` from `lib/features/home/presentation/widgets/` to `lib/shared/prayer_times/presentation/` — Home and Prayers both needed it, and direct feature-to-feature import would violate Constitution Principle I; `flutter analyze` clean on all touched files

**Checkpoint**: User Story 1 fully functional and independently testable/demoable.

---

## Phase 4: User Story 2 - Control per-prayer notification reminders (Priority: P2)

**Goal**: Per-prayer on/off toggles that persist locally, sync to the account when signed in, schedule/cancel a device reminder, and are gated by notification-permission state (prompt / denied-help / permanently-denied).

**Independent Test**: Toggle an individual prayer's notification, restart the app, and confirm the toggle state and its scheduled/cancelled reminder persisted — independent of the location card's content.

### Implementation for User Story 2

- [X] T013 [P] [US2] Create the `PrayerReminderSetting` entity and `NotificationPermissionStatus` enum in `lib/features/prayers/domain/entities/prayer_reminder_setting.dart` (data-model.md)
- [X] T014 [P] [US2] Create the abstract `PrayerNotificationSettingsRepository` interface in `lib/features/prayers/domain/repositories/prayer_notification_settings_repository.dart` (`getLocalSettings`, `saveLocalSetting`, `syncToRemote`, `reconcileWithRemote`)
- [X] T015 [P] [US2] Create `PrayerNotificationSettingModel` (Hive envelope `toJson`/`fromJson` + Supabase row mapping) in `lib/features/prayers/data/models/prayer_notification_setting_model.dart` (data-model.md persistence shapes)
- [X] T016 [US2] Implement `PrayerNotificationSettingsRepositoryImpl` in `lib/features/prayers/data/repositories/prayer_notification_settings_repository_impl.dart`: `getLocalSettings()` (defaults all five to enabled — spec.md Edge Cases), `saveLocalSetting()` (writes with `updatedAt = now`), `syncToRemote()` (fire-and-forget upsert, swallows exceptions), `reconcileWithRemote()` (pull, per-prayer last-write-wins, seed-if-fewer-than-5-rows) per contracts/supabase_sync_contract.md (depends on T013, T014, T015)
- [X] T017 [P] [US2] Unit test `PrayerNotificationSettingsRepositoryImpl` — default-all-enabled on empty Hive, `saveLocalSetting` persists `updatedAt` and survives a fresh instance, mirroring the real-Hive-box setup in `test/shared/prayer_times/prayer_times_repository_impl_test.dart`. SCOPE NOTE: `syncToRemote`/`reconcileWithRemote` (guest-skip, last-write-wins, seed) are NOT unit tested — `supabase_flutter`'s fluent query-builder chain has no practical mock/fake seam without a live or local Supabase instance; those paths are covered by quickstart.md Scenario 2's manual verification instead. 4/4 tests passing
- [X] T018 [P] [US2] Add `checkNotificationPermissionStatus()` to `lib/handlers/permission_handler.dart`, returning the raw tri-state (`granted`/`denied`/`permanentlyDenied`) from `permission_handler`'s `Permission.notification` rather than reusing the boolean-collapsing `_checkPermission()` helper (research.md R4); existing methods on this class are unchanged. Also added `openAppNotificationSettings()` for the permission-help cards' "Enable" control
- [X] T019 [P] [US2] Create `NotificationHandler` in `lib/handlers/notification_handler.dart`: `init()`, `scheduleReminder()`, `cancelReminder()`, `rescheduleAll()`, using deterministic per-prayer notification ids (fajr=1…isha=5) and Darwin presentation options for foreground+background delivery, per contracts/notification_scheduling_contract.md (depends on T001, T006). ADAPTATION: `rescheduleAll` takes a `({prayerCode, isEnabled})` record list rather than `List<PrayerReminderSetting>` directly, so `lib/handlers/` stays free of a `lib/features/prayers/` import (Constitution Principle I); schedules against an absolute UTC `TZDateTime` rather than resolving the device's IANA zone name, since every load reschedules fresh (no recurring local-time matching), avoiding an extra `flutter_timezone` dependency
- [X] T020 Register `NotificationHandler.instance.init()` in the app startup sequence in `lib/main.dart`, alongside the existing `Supabase.initialize`/`SharedPrefHandler.init` calls (depends on T019). Also wired `NotificationHandler.instance.navigatorKey` onto `MaterialApp.navigatorKey` so the tap-to-open callback (FR-016) can navigate without a `BuildContext`
- [X] T021 [P] [US2] Create the `PrayerNotificationSettingsState` sealed classes (`Initial`, `Loading`, `Loaded(settings, permissionStatus)`) in `lib/features/prayers/presentation/bloc/prayer_notification_settings_state.dart` (depends on T013)
- [X] T022 [US2] Implement `PrayerNotificationSettingsCubit` in `lib/features/prayers/presentation/bloc/prayer_notification_settings_cubit.dart`: `loadSettings()` (reconcile if signed in, check permission, reschedule all enabled reminders against `PrayerTimesCubit.instance`'s current times), `toggle()` (optimistic emit, persist, schedule/cancel, fire-and-forget sync), `requestNotificationPermission()`, `openNotificationSettings()`, per contracts/prayer_notification_settings_cubit_contract.md (depends on T016, T018, T019, T021)
- [X] T023 [P] [US2] Unit test `PrayerNotificationSettingsCubit` using `bloc_test`/`mocktail`: default-all-enabled emission, `toggle()` optimistic state + save/cancel calls, guest skips `syncToRemote`, `permissionStatus` mapping (denied/permanentlyDenied), and scheduling against `PrayerTimesCubit.instance`'s live times. BUG FOUND & FIXED: `GeocodingHandler` originally constructed its `Geocoding()` instance eagerly as a field, which crashed *any* code merely touching `PrayerTimesCubit.instance` in a unit-test process (no platform channel registered) — moved construction inside the already-`try`-wrapped call site so a missing platform interface degrades to `[]` like any other geocode failure, instead of crashing unrelated tests. 6/6 tests passing; full `test/shared/prayer_times/` suite (19 tests) re-verified green after the fix
- [X] T024 [US2] Add `BlocProvider<PrayerNotificationSettingsCubit>` to `PrayersPage` (`lib/features/prayers/presentation/pages/prayers_page.dart`), calling `loadSettings()` on create and re-checking permission status on app-resume (`WidgetsBindingObserver`/`didChangeAppLifecycleState`) per contracts/prayer_notification_settings_cubit_contract.md's "permission re-check on resume" (depends on T012, T022)
- [X] T025 [P] [US2] Extend `PrayerReminderTile` (`lib/features/prayers/presentation/widgets/prayer_reminder_tile.dart`) with the fixed "10 minutes before" caption and an on/off toggle bound to `PrayerNotificationSettingsCubit.toggle()`, visually disabled when `permissionStatus` is `denied`/`permanentlyDenied` (FR-003, FR-014) (depends on T011, T022)
- [X] T026 [P] [US2] Create `NotificationPermissionHelpCard` widget in `lib/features/prayers/presentation/widgets/notification_permission_help_card.dart` for the denied-but-not-permanent state, with an "Enable" control calling `requestNotificationPermission()`/`openNotificationSettings()` (FR-013)
- [X] T027 [P] [US2] Create `NotificationPermissionPermanentlyDeniedCard` widget in `lib/features/prayers/presentation/widgets/notification_permission_permanently_denied_card.dart`, with an "Enable" control calling `openNotificationSettings()` (FR-014)
- [X] T028 [US2] Wire permission-status branching into `PrayersView`: `requestNotificationPermission()` is invoked by the help card's own "Enable" tap (FR-012/013), render `NotificationPermissionHelpCard` / `NotificationPermissionPermanentlyDeniedCard` based on `state.permissionStatus`, and gate each tile's toggle interactivity on `permissionStatus == granted` (depends on T022, T024, T026, T027)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - See at a glance that all reminders are off (Priority: P3)

**Goal**: A persistent alert card at the top of the screen whenever every prayer's toggle is off, gone the instant any one is turned back on.

**Independent Test**: Turn off all five prayer notification toggles and confirm the alert card appears; turn any one back on and confirm it disappears without reopening the screen — independent of the location card and of any specific prayer's time.

### Implementation for User Story 3

- [X] T029 [US3] Create `PrayerRemindersOffBanner` widget in `lib/features/prayers/presentation/widgets/prayer_reminders_off_banner.dart`, rendered at the top of `PrayersPage` only when `settings.every((s) => !s.isEnabled)` is true in the current `PrayerNotificationSettingsCubit` `Loaded` state — a pure derivation, no new stored flag (FR-008, data-model.md) (depends on T022, T024)

**Checkpoint**: All three user stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and final validation across all stories

- [X] T030 [P] `flutter analyze` — zero new issues across `lib/features/prayers/`, `lib/handlers/notification_handler.dart`, `lib/handlers/geocoding_handler.dart`, `lib/handlers/permission_handler.dart`, and the modified `lib/shared/prayer_times/`/`lib/features/home/` files (full-repo `flutter analyze` re-run: the only findings are pre-existing, in files this feature never touched)
- [X] T031 [P] `dart format` run across all new/changed `lib/` and `test/` files (whitespace-only diffs)
- [~] T032 PARTIAL — `flutter build ios --simulator` succeeds with the new native deps (`flutter_local_notifications`, `geocoding`, `timezone`); installed and launched on an iOS simulator, confirmed no crash on startup (past `Supabase init` through `NotificationHandler.init()`/`SessionCubit.restoreSession()` to a stable Home screen). Could NOT drive the interactive quickstart.md scenarios (toggling, permission prompts, the all-off banner, reminder delivery) — this session has no touch-automation tool (`idb`/XCUITest) available, and `xcrun simctl privacy grant location` failed in this simulator/Xcode combination, so the Prayers screen itself (reached only via the Home edit icon, which requires a resolved location) could not be visually reached. **Needs a manual pass on a real device or a properly provisioned simulator before this feature is considered UI-verified.**
- [ ] T033 NOT DONE — pixel-parity comparison against the design reference. No design import happened in this implementation session (the `claude_design`/Figma MCP tooling referenced in the original feature brief was never invoked here) — there is no design reference available to compare against. The UI was built by matching the existing Sakinah design-token system (`AppColors`/`AppTypography`/`AppIcons`) and mirroring sibling widgets' visual style (`PrayerTimesCard`, `PrayerDayStrip`, `PrayerTimesUnavailableView`) rather than a pixel-exact source. **A follow-up pass importing the actual design file and comparing side-by-side is required before FR-019/SC-007 can be marked satisfied.**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T001/T006 (Setup) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T007) — no dependency on US2/US3
- **User Story 2 (Phase 4)**: Depends on Foundational (T007) and reuses `PrayerReminderTile`/`PrayersPage` from US1 (T011, T012) — independently testable per its own acceptance scenarios once those exist
- **User Story 3 (Phase 5)**: Depends on US2's Cubit/state existing (T022, T024) — this story is additive UI on top of US2's already-working toggles, per spec.md's own "Why this priority" framing
- **Polish (Phase 6)**: Depends on all three stories being complete

### Within Each User Story

- US1: shared-module change (T008) → its test (T009) and widgets (T010, T011) in parallel → page wiring (T012)
- US2: entity/interface/model (T013–T015) in parallel → repository impl (T016) → its test (T017); permission + notification handler additions (T018, T019) in parallel with the repository work → main.dart registration (T020); state (T021) → cubit (T022) → its test (T023); page/tile/permission-card wiring (T024–T028) last, since all depend on T022
- US3: single task (T029), depends only on US2's cubit/page being in place

### Parallel Opportunities

- All Setup tasks marked [P] (T001–T005) can run together; T006 follows T001
- T009, T010, T011 (US1) can run in parallel once T008 is done
- T013, T014, T015, T018, T019, T021 (US2) can all start in parallel once Foundational is done
- T025, T026, T027 (US2, different widget files) can run in parallel once T022 is done
- T030, T031 (Polish) can run in parallel

---

## Parallel Example: User Story 1

```bash
# After T008 (resolveDisplayLocation) is done, launch together:
Task: "Unit test resolveDisplayLocation() in test/shared/prayer_times/prayer_times_repository_impl_test.dart"
Task: "Create PrayerLocationCard widget in lib/features/prayers/presentation/widgets/prayer_location_card.dart"
Task: "Create display-only PrayerReminderTile widget in lib/features/prayers/presentation/widgets/prayer_reminder_tile.dart"
```

## Parallel Example: User Story 2 (entity/infra layer)

```bash
# Once Foundational (T007) is complete, launch together:
Task: "Create PrayerReminderSetting entity + NotificationPermissionStatus enum in lib/features/prayers/domain/entities/prayer_reminder_setting.dart"
Task: "Create PrayerNotificationSettingsRepository interface in lib/features/prayers/domain/repositories/prayer_notification_settings_repository.dart"
Task: "Create PrayerNotificationSettingModel in lib/features/prayers/data/models/prayer_notification_setting_model.dart"
Task: "Add checkNotificationPermissionStatus() to lib/handlers/permission_handler.dart"
Task: "Create NotificationHandler in lib/handlers/notification_handler.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md Scenario 1 independently
5. Demo: read-only Prayers screen showing today's schedule and location

### Incremental Delivery

1. Setup + Foundational → routed, empty Prayers screen
2. + User Story 1 → read-only schedule (MVP) → validate → demo
3. + User Story 2 → working per-prayer toggles, permission handling, scheduled reminders → validate → demo
4. + User Story 3 → all-off alert banner → validate → demo
5. Polish → analyze/format clean, quickstart scenarios re-run end to end, pixel-parity check

---

## Notes

- [P] tasks touch different files and have no unmet dependency on another incomplete task in the same batch
- [Story] label maps each task to its spec.md user story for traceability
- US2 is the largest phase because it introduces this feature's only new data/domain/cubit layer (Constitution Principle I) plus two new device capabilities (notification scheduling, notification permission) that didn't exist in the codebase before this feature
- Verify `flutter test` passes for T009, T017, T023 before considering their respective story phases done
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently
