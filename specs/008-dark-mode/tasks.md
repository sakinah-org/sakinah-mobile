---

description: "Task list for Dark Mode (specs/008-dark-mode)"
---

# Tasks: Dark Mode

**Input**: Design documents from `/specs/008-dark-mode/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Included for the extended `SettingsCubit` business logic only (`toggleDarkMode`/`loadPersistedSettings` persistence), per Constitution Principle VIII. UI-only widget/page work (the new toggle row, and the US3 theme-consistency fixes) is not required to ship tests. Not TDD-ordered — write alongside or immediately after the corresponding implementation task.

**Organization**: Tasks are grouped by user story (spec.md priorities) so each story is independently implementable and testable.

**Scope note**: US3's task list includes 7 pre-existing files found to hardcode light-only colors/typography (unrelated to the Settings toggle itself) — see plan.md's "Scope note" for why these were pulled into this feature rather than deferred.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Maps the task to spec.md's US1–US3
- File paths are exact, relative to the repository root

## Path Conventions

Single Flutter project — `lib/`, `test/`, `assets/lang/` at the repository root, per plan.md's Project Structure.

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Shared constants both US1 (toggle UI) and US2 (persistence) need. No new package dependencies for this feature (plan.md Technical Context), so there is no separate Setup phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 Add `isDarkMode = 'is_dark_mode'` key to `AppPersistenceDataKeys` (under the existing "Settings" section) in `lib/configurations/app_persistence_data_keys.dart`
- [X] T002 [P] Add `settingsDarkModeOption = 'settings_dark_mode_option'` key to `TranslationKeys` (alongside the other Settings keys) in `lib/configurations/app_translation_keys.dart`
- [X] T003 [P] Add `"settings_dark_mode_option": "Dark Mode"` to `assets/lang/en.json`
- [X] T004 [P] Add `"settings_dark_mode_option": "الوضع الداكن"` to `assets/lang/ar.json`

**Checkpoint**: Persistence key and translation strings exist. User story work can now begin.

---

## Phase 2: User Story 1 - Switch Between Light and Dark Theme (Priority: P1) 🎯 MVP

**Goal**: A toggle row on the Settings screen flips the app between light and dark appearance immediately, on every screen, with no restart.

**Independent Test**: Open Settings, tap the toggle, confirm every visible screen (current and any screen navigated to afterward) immediately renders in the newly selected theme (quickstart.md US1). Does not require verifying persistence across restart — that's US2.

### Implementation for User Story 1

- [X] T005 [US1] Create `SettingsToggleTile` widget — icon square (`AppIcons.appearance`) + label + trailing `Switch(value: ..., onChanged: ..., activeTrackColor: brandPrimary)`, following `SettingsOptionTile`'s layout and `PrayerReminderTile`'s `Switch` usage (research.md R2) — in `lib/features/settings/presentation/widgets/settings_toggle_tile.dart`
- [X] T006 [US1] Wire `SettingsToggleTile` into `SettingsPage`'s options-list container (after the existing Change Language row, inside the same rounded/divided `Container`), reading `context.watch<SettingsCubit>().isDarkMode` for the value and calling `SettingsCubit.instance.toggleDarkMode()` on change, using `translator.word(TranslationKeys.settingsDarkModeOption)` for the label — in `lib/features/settings/presentation/pages/settings_page.dart` (depends on T005, T002)

**Checkpoint**: Tapping the toggle switches the whole app's theme immediately (quickstart.md US1). Independently testable and demoable now — persistence lands in US2.

---

## Phase 3: User Story 2 - Theme Choice Persists Across Sessions (Priority: P1) 🎯 MVP

**Goal**: The selected theme survives app restarts, defaulting to light mode when nothing has been persisted yet.

**Independent Test**: Toggle to dark mode, force-quit, relaunch — app opens in dark mode. Toggle to light, force-quit, relaunch — app opens in light. Fresh install opens in light mode (quickstart.md US2).

### Implementation for User Story 2

- [X] T007 [US2] Extend `SettingsCubit.toggleDarkMode()` to persist `isDarkMode` to `SharedPrefHandler` under `AppPersistenceDataKeys.isDarkMode` after flipping the field and before emitting (removes the existing `// TODO: save the value in shared preferences`), per contracts/settings_cubit_dark_mode_contract.md, in `lib/shared/bloc/settings_cubit.dart` (depends on T001)
- [X] T008 [US2] Extend `SettingsCubit.loadPersistedSettings()` to hydrate `isDarkMode` from `AppPersistenceDataKeys.isDarkMode` when `SharedPrefHandler.instance!.contains(...)` is true, leaving the default (`false`) otherwise — mirroring the existing `locale` hydration guard — in `lib/shared/bloc/settings_cubit.dart` (same file as T007; depends on T007, T001)
- [X] T009 [US2] Extend `test/shared/bloc/settings_cubit_test.dart` with a `SettingsCubit.toggleDarkMode` group (flips `isDarkMode`, persists it under `AppPersistenceDataKeys.isDarkMode`, emits `LoadedState`) and add dark-mode cases to the existing `loadPersistedSettings` group (hydrates `true`/`false` from a persisted value; falls back to `false` when nothing is persisted) — depends on T007, T008

**Checkpoint**: User Stories 1 AND 2 both work independently — the toggle switches themes immediately and the choice survives a relaunch (quickstart.md US1 + US2).

---

## Phase 4: User Story 3 - Every Screen Renders Correctly in Dark Mode (Priority: P2)

**Goal**: Every screen, modal, bottom sheet, and dialog in the app — not just Settings — renders with dark-appropriate colors when dark mode is active, with no light-mode-only colors leaking through.

**Independent Test**: With dark mode active, navigate through Home, Prayer Times, Quran, Settings, the full auth flow (login/register/forgot-reset password/OTP), the language bottom sheet, and the logout confirmation dialog — confirm text stays readable and no light-only colors/white boxes appear (quickstart.md US3).

### Implementation for User Story 3

- [X] T010 [P] [US3] Make label and hint text colors theme-aware in `TextInputField` (replace hardcoded `color: Colors.black` label style with an `isDark`-conditional `AppColors.darkTextPrimary`/`lightTextPrimary`, matching the `isDark = Theme.of(context).brightness == Brightness.dark` pattern used elsewhere) in `lib/shared/widgets/fields/text_input_field.dart`
- [X] T011 [P] [US3] Make the selected tab's icon/label color theme-aware in `MainBottomNavigationBar` (`selectedItemColor` and the 3 `iconColor` ternaries: `isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary`) in `lib/features/main/ui/widgets/main_bottom_navigation_bar.dart`
- [X] T012 [P] [US3] Make the "View All" link color theme-aware in `TitledComponent` (`isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary`) in `lib/shared/widgets/titled_component.dart`
- [X] T013 [P] [US3] Make `LoginPage` theme-aware: compute `isDark` once in `build()`, swap `AppTypography.h1Light`/`body2Light` for an `isDark`-conditional Light/Dark style, swap the two `AppColors.lightTextTertiary` prefix-icon colors, and swap the loading-spinner's `AppColors.lightOnBrand` for `isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand` — in `lib/features/auth/presentation/pages/login_page.dart`
- [X] T014 [P] [US3] Same treatment as T013 for `RegisterPage` (4x `lightTextTertiary` icon colors, `h1Light`/`body2Light` x2, spinner color), plus delete the hardcoded `appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white)` overrides so it inherits the already-themed `AppBarTheme` — in `lib/features/auth/presentation/pages/register_page.dart`
- [X] T015 [P] [US3] Same treatment as T013 for `ForgotPasswordPage` (1x `lightTextTertiary`, `h1Light`/`body2Light`, spinner color), plus delete the same hardcoded white `AppBar` overrides — in `lib/features/auth/presentation/pages/forgot_password_page.dart`
- [X] T016 [P] [US3] Same treatment as T013 for `ResetPasswordPage` (1x `lightTextTertiary`, `h1Light`/`body2Light`, spinner color) — in `lib/features/auth/presentation/pages/reset_password_page.dart`
- [X] T017 [P] [US3] Same treatment as T013 for `VerifyOtpPage`, including the `Pinput` `defaultPinTheme`/`focusedPinTheme` (`AppColors.lightSurface`, `lightBorder`, `lightBrandPrimary`, `AppTypography.h2Light`) and the two `body2Light` text styles — in `lib/features/auth/presentation/pages/verify_otp_page.dart`
- [ ] T018 [US3] Run quickstart.md's US3 + Edge Cases validation pass in dark mode across Home, Prayer Times, Quran, Settings, the full auth flow, the language bottom sheet, and the logout confirmation dialog — confirm no remaining light-mode-only colors (depends on T010–T017). **Not completed in this session**: `flutter run -d macos` failed on a pre-existing, unrelated environment issue (CocoaPods specs repo too out-of-date to resolve `Firebase/CoreOnly`; `pod repo update` needed) before the app could even build, so no simulator/device was available to click through. `flutter analyze` (0 errors) and the full `flutter test` suite (only 5 pre-existing failures, confirmed present on `master` before this branch — network-mocking issues in `login_bloc_test.dart`/`ayah_repository_impl_test.dart` and the stock unmodified `widget_test.dart`) were used as a substitute, plus manual code review of every touched file against the same `isDark ? darkX : lightX` pattern already proven elsewhere in the app. A real device/simulator pass is still recommended once the CocoaPods environment issue is resolved.

**Checkpoint**: All three user stories independently functional — dark mode works end-to-end with no known light-mode-only screens left (quickstart.md US1–US3 all pass).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. BLOCKS User Stories 1 and 2 (both need the persistence key/translation key). Does not block US3 (T010–T017 touch none of Phase 1's files).
- **User Story 1 (Phase 2)**: Depends on Foundational (T002 for the label key). Independent of US2/US3.
- **User Story 2 (Phase 3)**: Depends on Foundational (T001 for the persistence key). Independent of US1's files (different files: `settings_toggle_tile.dart`/`settings_page.dart` vs. `settings_cubit.dart`), though US1's toggle is what a user would actually tap to exercise US2's persistence in an end-to-end demo.
- **User Story 3 (Phase 4)**: Fully independent of Phases 1–3 — none of its 8 files overlap with Foundational, US1, or US2's files. Can be implemented and merged first, last, or in parallel with the others.

### Within Each User Story

- US1: T005 (widget) before T006 (wiring it into the page).
- US2: T007 before T008 (same file, sequential edits), both before T009 (test needs the implementation to assert against).
- US3: T010–T017 are fully independent (8 distinct files) and can all run in parallel; T018 (manual validation) runs last, after all of them.

### Parallel Opportunities

- T002, T003, T004 (Phase 1) — different files, no dependency.
- All of T010–T017 (Phase 4 / US3) — 8 distinct files, zero cross-dependencies.
- Phase 2 (US1) and Phase 3 (US2) can be built by different people in parallel once Phase 1 is done — they touch disjoint file sets.
- Phase 4 (US3) can be built in parallel with everything else — it depends on nothing from Phases 1–3.

---

## Parallel Example: User Story 3

```bash
# Launch all 8 independent fixes together once Phase 1 is done:
Task: "Make TextInputField label/hint colors theme-aware in lib/shared/widgets/fields/text_input_field.dart"
Task: "Make MainBottomNavigationBar selected color theme-aware in lib/features/main/ui/widgets/main_bottom_navigation_bar.dart"
Task: "Make TitledComponent's View All link color theme-aware in lib/shared/widgets/titled_component.dart"
Task: "Make LoginPage theme-aware in lib/features/auth/presentation/pages/login_page.dart"
Task: "Make RegisterPage theme-aware (+ remove hardcoded white AppBar) in lib/features/auth/presentation/pages/register_page.dart"
Task: "Make ForgotPasswordPage theme-aware (+ remove hardcoded white AppBar) in lib/features/auth/presentation/pages/forgot_password_page.dart"
Task: "Make ResetPasswordPage theme-aware in lib/features/auth/presentation/pages/reset_password_page.dart"
Task: "Make VerifyOtpPage + its Pinput themes theme-aware in lib/features/auth/presentation/pages/verify_otp_page.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Foundational.
2. Complete Phase 2: User Story 1 (toggle switches the app's theme).
3. Complete Phase 3: User Story 2 (choice persists across restarts).
4. **STOP and VALIDATE**: Run quickstart.md US1 + US2. This is a fully working, shippable dark-mode toggle — the feature's core value (spec.md frames both as P1).
5. Deploy/demo if ready.

### Incremental Delivery

1. Foundational → toggle + persistence (US1 + US2) → MVP, deploy/demo.
2. Add User Story 3 → run quickstart.md's full cross-screen pass → deploy/demo with zero known light-mode-only screens.

### Parallel Team Strategy

With multiple developers: after Phase 1, one developer takes US1+US2 (both touch `SettingsCubit`/Settings UI — natural to pair), while another takes all of US3's 8 independent file fixes in parallel. No coordination needed between the two tracks until final `flutter analyze`/quickstart validation.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to spec.md's US1/US2/US3.
- `dart format` + `flutter analyze` clean before considering any task done (Constitution Principle VIII).
- Commit after each task or logical group.
- Stop at either checkpoint (end of Phase 3, end of Phase 4) to validate independently via quickstart.md.
