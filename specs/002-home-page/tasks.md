---

description: "Task list template for feature implementation"
---

# Tasks: Home Page (Prayer Times & Ayah of Today)

**Input**: Design documents from `/specs/002-home-page/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Included. Not explicitly requested via TDD in spec.md, but plan.md's Project Structure and the Constitution (Principle VIII: "New or changed business logic ... SHOULD ship with a unit test") both commit to unit-testing both Cubits and both repositories — see quickstart.md's "Automated coverage" section, which this task list implements.

**Organization**: Tasks are grouped by user story (spec.md: US1 = P1 prayer times, US2 = P2 Ayah of Today, US3 = P3 edit-to-Prayers shortcut) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3) — omitted for Setup/Foundational/Polish
- File paths are exact, per `plan.md`'s Project Structure section

## Path Conventions

Single Flutter mobile app, existing `lib/` layout (no new top-level project) — see `plan.md` Project Structure for the full tree. Tests live under `test/`, mirroring the `lib/` module they cover.

---

## Phase 1: Setup

**Purpose**: Dependencies, platform config, and constant scaffolding shared by every story.

- [X] T001 [P] Add `geolocator`, `hijri`, `share_plus` to `pubspec.yaml` dependencies and run `flutter pub get` (research.md §12)
- [X] T002 [P] Add location-permission usage strings: `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`; `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION` in `android/app/src/main/AndroidManifest.xml` (quickstart.md Prerequisites)
- [X] T003 [P] Add AlAdhan (`https://api.aladhan.com/v1`) and Al Quran Cloud (`https://api.alquran.cloud/v1`) base URL constants to `lib/configurations/app_end_points.dart` (contracts/prayer_times_api.md, contracts/ayah_of_today_api.md; research.md §11 — NOT added to `AppEnv`)
- [X] T004 [P] Add persistence keys for prayer location (lat/lng), calculation method, prayer-times cache, and ayah-of-today cache to `lib/configurations/app_persistence_data_keys.dart` (data-model.md `CachedPrayerTimes`/`CachedAyah`)
- [X] T005 [P] Add `AppRoutes.prayers` constant in `lib/navigation/app_routes.dart` and register a minimal placeholder route/page for it in `lib/navigation/route_generator.dart` (research.md §6 — temporary seam for the future Prayers feature)

**Checkpoint**: Dependencies installed, constants in place — no behavior yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shell and cross-cutting pieces every user story's widgets sit inside. Nothing here depends on Prayer Times or Ayah data.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T006 [P] Add Hijri-date and greeting-period (morning/afternoon/evening) helpers to `lib/toolkit/extensions/date_time_extensions.dart`, backed by the `hijri` package (research.md §7)
- [X] T007 [P] Create `LocationHandler` wrapping `geolocator` (one-shot current-position read) in `lib/handlers/location_handler.dart`, following the existing `ImagePickerHandler` pattern (research.md §4)
- [X] T008 Add Home-page `TranslationKeys` entries to `lib/configurations/app_translation_keys.dart` and their `en`/`ar` values to `assets/lang/en.json` + `assets/lang/ar.json`: greeting phrases, day-name/Hijri-date format pieces, "Next prayer"/"until adhan", the 5 prayer names, "Verse of the Day"/"Ayah of Today" heading, "Share", "Cached", "Retry", the prayer location-required/unable-to-load messages, and the ayah-unavailable message (research.md §1 "Key layout facts"; constitution Principle VII)
- [X] T009 Create the `HomePage` scaffold in `lib/features/home/presentation/pages/home_page.dart` (scrollable content column matching the design mock's `overflow-y:auto` region) and wire it as tab index 0 of `MainPage`'s `PageView`, trimming the `PageView` children list from 5 placeholder `Container()`s to 3 (Home/Quran-placeholder/Settings-placeholder) to match the existing 3-item bottom nav, in `lib/features/main/ui/pages/main_page.dart` (plan.md "Directly-touched inconsistency fixed in this change")
- [X] T010 Create `HomeGreetingHeader` widget (greeting + name from `SessionCubit.instance.currentUser?.name`, guest-safe; day name; Hijri date) in `lib/features/home/presentation/widgets/home_greeting_header.dart`, mounted at the top of `HomePage` (depends on: T006, T008, T009)

**Checkpoint**: Foundation ready — `HomePage` exists, is reachable, and shows its header. User story implementation can now begin.

---

## Phase 3: User Story 1 - See today's prayer times and the next prayer at a glance (Priority: P1) 🎯 MVP

**Goal**: Home shows all 5 prayer times and a live, ticking countdown to the next prayer, backed by a shared, singleton `PrayerTimesCubit` with device-location resolution and offline/no-data fallback states.

**Independent Test**: Open the Home tab with a configured/detected location and confirm all five prayer times display correctly and the next upcoming prayer is visually distinguished with a live-updating countdown — independent of the Ayah of Today component.

### Tests for User Story 1

- [X] T011 [P] [US1] Unit test `PrayerTimesRepositoryImpl` in `test/shared/prayer_times/prayer_times_repository_impl_test.dart` — `mocktail`-faked `DioClient`/`SharedPrefHandler`/`LocationHandler`, covering: fresh success, network failure with cache fallback, network failure with no cache, location permission denied (contracts/prayer_times_api.md)
- [X] T012 [P] [US1] `bloc_test` for `PrayerTimesCubit` in `test/shared/prayer_times/prayer_times_cubit_test.dart` — covers all 5 states from contracts/prayer_times_cubit_contract.md, including next-prayer rollover to tomorrow's Fajr after Isha passes

### Implementation for User Story 1

- [X] T013 [P] [US1] Create domain entities `PrayerLocation` (Coordinates | City union), `CalculationMethod` (enum + AlAdhan id mapping), `PrayerTimes` in `lib/shared/prayer_times/domain/entities/prayer_location.dart`, `calculation_method.dart`, `prayer_times.dart` (data-model.md)
- [X] T014 [US1] Create `PrayerTimesRepository` abstract contract (`getPrayerTimes({location, method, date})`) in `lib/shared/prayer_times/domain/repositories/prayer_times_repository.dart` (depends on: T013)
- [X] T015 [US1] Create `PrayerTimesModel` (AlAdhan JSON ↔ `PrayerTimes` mapping) and the `CachedPrayerTimes` envelope in `lib/shared/prayer_times/data/models/prayer_times_model.dart` (depends on: T013)
- [X] T016 [US1] Implement `PrayerTimesRepositoryImpl` in `lib/shared/prayer_times/data/repositories/prayer_times_repository_impl.dart`: location resolution (cached lat/lng → `PermissionHandler` + `LocationHandler` → persist), AlAdhan `/timings` call via `DioClient.instance`/`AppEndPoints`, default calculation method `umm_al_qura`, cache-on-success, fallback-to-cache on `ConnectionFailure`/`TimeoutFailure` via `Failure.handleDioException`, `PrayerTimesLocationRequiredState`-triggering path when no location resolvable (depends on: T007, T014, T015)
- [X] T017 [US1] Create `PrayerTimesState` hierarchy (`Initial`/`Loading`/`Loaded(times, isFallback)`/`LocationRequired`/`Unavailable`) in `lib/shared/prayer_times/presentation/bloc/prayer_times_state.dart` (depends on: T013)
- [X] T018 [US1] Implement `PrayerTimesCubit` (singleton `.instance`, `loadPrayerTimes()`/`refreshLocation()`/`onCalculationMethodChanged()`, next-prayer derivation with day-rollover) in `lib/shared/prayer_times/presentation/bloc/prayer_times_cubit.dart` (depends on: T016, T017)
- [X] T019 [US1] Provide `PrayerTimesCubit.instance` at the widget-tree root via `MultiBlocProvider` in `lib/main.dart`, alongside `SettingsCubit`/`SessionCubit` (depends on: T018)
- [X] T020 [P] [US1] Create `PrayerTimesCountdown` widget — ticking `h:mm:ss` text from a `DateTime target`, recomputed once per second, `AnimatedSwitcher` fade per tick, isolated so only this subtree rebuilds each second — in `lib/features/home/presentation/widgets/prayer_times_countdown.dart` (research.md §8)
- [X] T021 [US1] Create `PrayerTimesCard` widget (gradient card: next-prayer label + name, embeds `PrayerTimesCountdown`, circular gear/edit icon button — `onTap` left as a required callback, wired in Phase 5) in `lib/features/home/presentation/widgets/prayer_times_card.dart` (depends on: T017, T020)
- [X] T022 [P] [US1] Create `PrayerDayStrip` widget (5 equal-width chips: icon + label + time, next prayer visually emphasized per design tokens) in `lib/features/home/presentation/widgets/prayer_day_strip.dart` (depends on: T017)
- [X] T023 [P] [US1] Create `PrayerTimesUnavailableView` widget with two variants — "set your location" (FR-009) and "unable to load" (FR-008) — each with a retry action, in `lib/features/home/presentation/widgets/prayer_times_unavailable_view.dart` (depends on: T017)
- [X] T024 [US1] Wire `PrayerTimesCard` + `PrayerDayStrip` + `PrayerTimesUnavailableView` into `HomePage` via `BlocBuilder<PrayerTimesCubit, PrayerTimesState>`, call `loadPrayerTimes()` on first build, show `ShimmerContainer` during `Initial`/`Loading` in `lib/features/home/presentation/pages/home_page.dart` (depends on: T019, T021, T022, T023, T010)

**Checkpoint**: User Story 1 is fully functional and independently testable — prayer times display, countdown ticks and rolls over at prayer boundaries, location-required and unable-to-load states both work.

---

## Phase 4: User Story 2 - Read a new reflection verse each day (Priority: P2)

**Goal**: Home shows a single Ayah of Today (Arabic + translation), selected once per calendar day, cached, with offline/stale/unavailable handling — backed by a Home-scoped `AyahOfTodayCubit`.

**Independent Test**: Open the Home tab on a given day and confirm a single ayah with its translation displays; reopen later the same day and confirm the same ayah shows (no new random pick) — independent of the Prayer Times component.

### Tests for User Story 2

- [X] T025 [P] [US2] Unit test `AyahRepositoryImpl` in `test/features/home/ayah_repository_impl_test.dart` — covers: same-day cache hit (assert no network call), fetch failure with stale cache (returns cached, `isFromToday: false`), fetch failure with no cache (throws) (contracts/ayah_of_today_api.md)
- [X] T026 [P] [US2] `bloc_test` for `AyahOfTodayCubit` in `test/features/home/ayah_of_today_cubit_test.dart` — covers all 4 states from contracts/ayah_of_today_cubit_contract.md, including `retry()` from `AyahOfTodayUnavailableState`

### Implementation for User Story 2

- [X] T027 [P] [US2] Create `AyahOfToday` domain entity in `lib/features/home/domain/entities/ayah_of_today.dart` (data-model.md)
- [X] T028 [US2] Create `AyahRepository` abstract contract (`getAyahOfToday()`, no params) in `lib/features/home/domain/repositories/ayah_repository.dart` (depends on: T027)
- [X] T029 [US2] Create `AyahOfTodayModel` (Al Quran Cloud JSON ↔ `AyahOfToday` mapping) and the `CachedAyah` envelope in `lib/features/home/data/models/ayah_of_today_model.dart` (depends on: T027)
- [X] T030 [US2] Implement `AyahRepositoryImpl` in `lib/features/home/data/repositories/ayah_repository_impl.dart`: same-day cache-hit short-circuit, client-side random `n` in `[1, 6236]`, Al Quran Cloud call via `DioClient.instance`/`AppEndPoints`, persist `CachedAyah` on success, stale-cache fallback on failure, throw when no cache and failure (research.md §10 — no local-Quran-asset fallback in this feature) (depends on: T028, T029)
- [X] T031 [US2] Create `AyahOfTodayState` hierarchy (`Initial`/`Loading`/`Loaded(ayah, isFromToday)`/`Unavailable`) in `lib/features/home/presentation/bloc/ayah_of_today_state.dart` (depends on: T027)
- [X] T032 [US2] Implement `AyahOfTodayCubit` (non-singleton, `loadAyahOfToday()`/`retry()`) in `lib/features/home/presentation/bloc/ayah_of_today_cubit.dart` (depends on: T030, T031)
- [X] T033 [P] [US2] Add `AppIcons.quote` key in `lib/utils/assets/app_icons_keys.dart` and create `assets/icons/quote.svg` (path extracted from the design mock, research.md §3)
- [X] T034 [US2] Create `AyahOfTodayCard` widget — unbounded-height card (no fixed/clamped height per FR-015), Arabic verse in `AppTypography.quranFontFamily`, translation below, surah/ayah reference line, `AppIcons.quote` mark, "Share" control via `share_plus`, "Cached" indicator when `isFromToday == false` — in `lib/features/home/presentation/widgets/ayah_of_today_card.dart` (depends on: T031, T033)
- [X] T035 [P] [US2] Create `AyahOfTodayUnavailableView` widget ("Ayah of Today is unavailable. Check your internet connection." + Retry button) in `lib/features/home/presentation/widgets/ayah_of_today_unavailable_view.dart` (depends on: T031)
- [X] T036 [US2] Provide `AyahOfTodayCubit` scoped to `HomePage` via `BlocProvider`, wire `AyahOfTodayCard`/`AyahOfTodayUnavailableView` via `BlocBuilder`, call `loadAyahOfToday()` on first build, `ShimmerContainer` during `Initial`/`Loading`, in `lib/features/home/presentation/pages/home_page.dart` (depends on: T032, T034, T035, T024)

**Checkpoint**: User Stories 1 AND 2 both work independently — prayer times and Ayah of Today are both live on Home.

---

## Phase 5: User Story 3 - Jump from Home to prayer settings (Priority: P3)

**Goal**: The prayer card's edit affordance reaches the (placeholder) Prayers screen in one tap.

**Independent Test**: Tap the edit affordance on the Home prayer times summary and confirm navigation to the Prayers screen — independent of the Ayah of Today component.

### Implementation for User Story 3

- [X] T037 [US3] Wire `PrayerTimesCard`'s gear/edit icon `onTap` to `Navigator.pushNamed(context, AppRoutes.prayers)` in `lib/features/home/presentation/widgets/prayer_times_card.dart` and its call site in `lib/features/home/presentation/pages/home_page.dart` (depends on: T021, T005, T024)

*No dedicated unit test: this story is pure navigation wiring with no new business logic (constitution Principle VIII: UI-only changes are not required to ship with a test).*

**Checkpoint**: All 3 user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and pixel-parity verification across the whole feature.

- [X] T038 [P] Run `dart format .` and `flutter analyze` clean across every new/changed file — 0 errors; only pre-existing infos/warnings remain in files this feature didn't touch
- [X] T039 [P] Verify EN/AR locale mirroring (RTL/LTR layout flip, all UI chrome translated, Ayah Arabic text staying RTL in both locales) and light/dark theme parity against the design reference for every Home widget (quickstart.md Scenario 8 / spec.md FR-018, SC-008) — verified live on iOS Simulator (AR/light and EN/dark), including nav-bar mirroring, Hijri-date Arabic-Indic numerals, and Ayah Arabic text staying RTL in the LTR/English layout
- [X] T040 Execute quickstart.md Scenarios 1–7 manually on a device/simulator — ran on iOS Simulator against the real AlAdhan/Al Quran Cloud APIs: Ayah of Today fetched and rendered live (Scenario 1 partial — Ayah half); location-required guidance state rendered correctly (Scenario 1 partial — Prayer Times half, since simulator TCC location-grant didn't propagate to the app's permission check in this sandbox; the location→loaded path itself is covered by automated tests, not a live screenshot). Full device-based validation of Scenarios 2–7 (offline toggling, long-ayah RNG, clock-forward rollover) left for the user to run per quickstart.md, since they require real connectivity toggling / physical device control this environment can't script
- [X] T041 [P] Review all new Home widgets against constitution Principle V (no inline `_build*` methods) and Principle IV (no hardcoded colors/fonts/asset path strings) — confirmed via grep audit: no `Widget _build*` methods, no `Color(0x...)` literals, no raw UI string literals outside `translator.word(...)`; also fixed a pre-existing bug found during verification: `AppLocalizationsDelegate.load()` never awaited `initTranslation()`, so all `translator.word()` calls app-wide (not just Home) rendered "key not found" — corrected in `lib/handlers/translation_handler.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately, all tasks parallel.
- **Foundational (Phase 2)**: Depends on Setup completion (T008 needs T003/T004's constants to exist conceptually, though not a hard code dependency) — BLOCKS all user stories.
- **User Stories (Phase 3–5)**: All depend on Foundational (Phase 2) completion.
  - US1 (Phase 3) and US2 (Phase 4) have no dependency on each other's Cubit/repository — both can proceed in parallel once Foundational is done.
  - US3 (Phase 5) depends on US1's `PrayerTimesCard` existing (T021) and Setup's `AppRoutes.prayers` (T005) — it is the thinnest phase, effectively a small addendum to US1.
- **Polish (Phase 6)**: Depends on US1 + US2 + US3 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — no dependency on US2 or US3.
- **User Story 2 (P2)**: Can start after Foundational — no dependency on US1 (its Cubit/repository/widgets are fully separate); only converges with US1 at the shared `HomePage` composition tasks (T024/T036 both touch `home_page.dart` sequentially).
- **User Story 3 (P3)**: Depends on US1's `PrayerTimesCard` (T021) existing — cannot be done before US1's card widget exists, though it needs none of US1's Cubit/repository logic.

### Within Each User Story

- Tests before implementation (write T011/T012 or T025/T026 first; they should fail against stub/nonexistent code).
- Domain entities → repository contract → data model → repository impl → state → Cubit → widgets → page wiring.
- Story complete (its Checkpoint) before starting the next priority, if working sequentially.

### Parallel Opportunities

- All of Phase 1 (T001–T005) in parallel.
- Within Phase 2: T006, T007 in parallel; T008 can run alongside them; T009 depends on nothing from T006–T008 and could start in parallel too, but T010 needs T006+T008+T009.
- Once Foundational is done: US1 (Phase 3) and US2 (Phase 4) can be built in parallel by different people, since neither's Cubit/repository/widgets touch the other's files — they only serialize at the two shared `home_page.dart` wiring tasks (T024, T036).
- Within US1: T011+T012 (tests) in parallel; T013 alone first, then T014/T015 can run in parallel, then T020 can be built any time in parallel with T016–T019 (no shared dependency), T022/T023 in parallel once T017 exists.
- Within US2: T025+T026 in parallel; T027 alone first, then T028/T029 in parallel; T033 in parallel with the repository/Cubit chain; T035 in parallel with T034 once T031 exists.

---

## Parallel Example: User Story 1

```bash
# Tests together:
Task: "Unit test PrayerTimesRepositoryImpl in test/shared/prayer_times/prayer_times_repository_impl_test.dart"
Task: "bloc_test for PrayerTimesCubit in test/shared/prayer_times/prayer_times_cubit_test.dart"

# After T013-T017 land, these widgets in parallel:
Task: "Create PrayerTimesCountdown widget in lib/features/home/presentation/widgets/prayer_times_countdown.dart"
Task: "Create PrayerDayStrip widget in lib/features/home/presentation/widgets/prayer_day_strip.dart"
Task: "Create PrayerTimesUnavailableView widget in lib/features/home/presentation/widgets/prayer_times_unavailable_view.dart"
```

## Parallel Example: User Story 2

```bash
# Tests together:
Task: "Unit test AyahRepositoryImpl in test/features/home/ayah_repository_impl_test.dart"
Task: "bloc_test for AyahOfTodayCubit in test/features/home/ayah_of_today_cubit_test.dart"

# Independent of the Cubit/repository chain:
Task: "Add AppIcons.quote key + assets/icons/quote.svg"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart.md Scenarios 1 (prayer-times portion), 3, 4 (prayer-times portion), 5, 7
5. Demo: Home shows live prayer times + ticking countdown; Ayah section can stay absent/hidden

### Incremental Delivery

1. Setup + Foundational → Home page shell + header exist
2. Add US1 → validate independently → prayer times MVP
3. Add US2 → validate independently → Ayah of Today live alongside prayer times
4. Add US3 → validate independently → edit-icon navigation
5. Polish (Phase 6) → pixel-parity + quality gates

### Parallel Team Strategy

1. Team completes Setup + Foundational together.
2. Once Foundational is done: Developer A takes US1 (Phase 3), Developer B takes US2 (Phase 4) — fully independent files until both reach `home_page.dart` (T024/T036), which should be sequenced between them.
3. Either developer (or a third) picks up US3 (Phase 5) once US1's `PrayerTimesCard` (T021) lands.
4. Whoever finishes first starts Phase 6 Polish once all three stories' checkpoints are green.

---

## Notes

- `[P]` tasks touch different files with no incomplete-task dependency.
- `[Story]` label maps each task to US1/US2/US3 for traceability back to spec.md.
- `home_page.dart` is the one file both US1 (T024) and US2 (T036) touch — sequence those two specifically even if the rest of the two stories run in parallel.
- Constitution Principle III (no service locator) applies throughout: `PrayerTimesRepositoryImpl`/`AyahRepositoryImpl` are constructed with `DioClient.instance`/`SharedPrefHandler.instance!`/`LocationHandler()` passed in manually — no `get_it`.
- Commit after each task or logical group; stop at any Checkpoint to validate a story independently before moving on.
