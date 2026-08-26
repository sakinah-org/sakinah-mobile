# Implementation Plan: Dark Mode

**Branch**: `008-dark-mode` | **Date**: 2026-08-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-dark-mode/spec.md`

## Summary

Close out the app's existing (but incomplete) dark-mode wiring: `lightTheme`/`darkTheme` (`lib/utils/style/app_theme.dart`) and their full color tokens (`lib/utils/style/app_colors.dart`) already exist and are already applied via `MaterialApp.themeMode` driven by `SettingsCubit.instance.isDarkMode` (`lib/main.dart`). What's missing is (1) a visible toggle control on the Settings screen, and (2) persistence — `SettingsCubit.toggleDarkMode()` currently has a `// TODO: save the value in shared preferences` and `loadPersistedSettings()` never hydrates `isDarkMode` on launch, so the choice is lost on every restart. This feature adds a `SettingsToggleTile` (Switch-based, matching the existing `PrayerReminderTile` toggle pattern) as a new row in the Settings options list, and extends `SettingsCubit` to persist/restore `isDarkMode` through `SharedPrefHandler`, mirroring exactly how `locale` is already persisted (`AppPersistenceDataKeys.appLocale` / `setLocale` / `loadPersistedSettings`).

**Scope note (added at `/speckit-tasks` time)**: Auditing FR-007/US3 ("every screen renders correctly in dark mode") surfaced 7 pre-existing files that hardcode light-only colors/typography regardless of theme — `lib/shared/widgets/fields/text_input_field.dart`, `lib/features/main/ui/widgets/main_bottom_navigation_bar.dart`, `lib/shared/widgets/titled_component.dart`, and all 5 auth screens (`login_page.dart`, `register_page.dart`, `forgot_password_page.dart`, `reset_password_page.dart`, `verify_otp_page.dart`). The user opted to fix all of them as part of this feature (rather than deferring as a follow-up) so dark mode has no known-broken screens at ship time. See tasks.md US3 for the itemized fix list.

## Technical Context

**Language/Version**: Dart (SDK `^3.5.3`), Flutter (stable channel matching `pubspec.yaml`)

**Primary Dependencies**: `flutter_bloc` (existing `SettingsCubit` singleton), `hive_flutter` via `SharedPrefHandler` (persistence) — no new packages.

**Storage**: Hive (`SharedPrefHandler`) — one new key, `AppPersistenceDataKeys.isDarkMode`. No SQL/remote schema changes.

**Testing**: `bloc_test` for the extended `SettingsCubit` behavior (`toggleDarkMode` persistence, `loadPersistedSettings` hydration), per Constitution Principle VIII. UI-only widget code (`SettingsToggleTile`) is not required to ship tests.

**Target Platform**: iOS + Android (Flutter mobile app) — theming is a pure Flutter/`ThemeData` concern, no platform-specific code.

**Performance Goals**: Theme switch is a synchronous cubit `emit()` that flips `MaterialApp.themeMode`; Flutter's own theme-transition rebuild satisfies SC-001 (<1s, effectively immediate) with no extra work needed.

**Constraints**: Exactly two theme states (light/dark), no system-appearance-follow mode (spec.md Assumptions). No new colors — `AppColors.dark*`/`light*` tokens are already complete and already consumed by `lightTheme`/`darkTheme`, so FR-008 (dark colors match the design system) is already satisfied by existing code; this feature does not touch `app_colors.dart` or `app_theme.dart`.

**Scale/Scope**: One new widget (`SettingsToggleTile`), one new row in `SettingsPage`'s options list, two extended `SettingsCubit` methods (`toggleDarkMode`, `loadPersistedSettings`), one new persistence key, a handful of new translation keys.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design — still passes, no new violations introduced by the design artifacts below.*

| Principle | Check | Result |
|---|---|---|
| I. Feature-First, Complexity-Scaled Architecture | Settings stays UI-only (`presentation/` only, per its existing structure). Theme state is extended on the existing `SettingsCubit` (`lib/shared/bloc/`) rather than a new cubit — checked first per Development Workflow step 1. | PASS |
| II. BLoC/Cubit State Management | No new state-management library, no new cubit. `SettingsCubit` keeps its existing singleton pattern (`_internal()` + `static instance`); `toggleDarkMode`/`loadPersistedSettings` already exist as named methods, just gain a persistence step. | PASS |
| III. No Service-Locator DI | No `get_it`/`injectable`. `SettingsToggleTile` reads `SettingsCubit.instance` via `context.watch<SettingsCubit>()`, same pattern as the existing language row's `context.watch<SettingsCubit>().locale` in `SettingsPage`. | PASS |
| IV. Centralized Design System | Zero new colors/typography needed — `AppColors.dark*/light*` tokens already exist and are already wired into `darkTheme`/`lightTheme` (research.md R1). Icon reuses the existing, currently-unused `AppIcons.appearance` (`assets/icons/appearance.svg`) — no new asset. | PASS |
| V. Reusable Widgets Over Inline Build Methods | New `SettingsToggleTile` is its own `StatelessWidget` under `lib/features/settings/presentation/widgets/`, following the existing `SettingsOptionTile`/`PrayerReminderTile` pattern — not an inline `_buildX()` in `SettingsPage`. | PASS |
| VI. Dio-Based Network Layer | Not applicable — no network calls in this feature. | PASS (N/A) |
| VII. Configuration/Env/Localization | New persistence key added to `AppPersistenceDataKeys` (not a raw string); new user-facing strings (toggle label) added to `TranslationKeys` + both `assets/lang/{en,ar}.json`. | PASS |
| VIII. Naming/Formatting/Test Discipline | `dart format` + `flutter analyze` clean before completion; `bloc_test` coverage added for the extended `SettingsCubit` persistence/hydration logic. | PASS |

No new dependencies. No entries needed in Complexity Tracking — no principle violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/008-dark-mode/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/            # Phase 1 output
│   └── settings_cubit_dark_mode_contract.md
└── tasks.md              # Phase 2 output (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── shared/
│   └── bloc/
│       └── settings_cubit.dart              # EXTENDED: toggleDarkMode() persists; loadPersistedSettings() hydrates isDarkMode
├── configurations/
│   ├── app_persistence_data_keys.dart       # EXTENDED: isDarkMode key
│   └── app_translation_keys.dart            # EXTENDED: settingsDarkModeOption key
├── features/
│   ├── settings/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── settings_page.dart       # EXTENDED: new SettingsToggleTile row in the options list
│   │       └── widgets/
│   │           └── settings_toggle_tile.dart # NEW: Switch-based options-list row
│   ├── main/
│   │   └── ui/
│   │       └── widgets/
│   │           └── main_bottom_navigation_bar.dart  # EXTENDED (US3): theme-aware selected color
│   └── auth/
│       └── presentation/
│           └── pages/                       # EXTENDED (US3): theme-aware colors/typography, all 5 files
│               ├── login_page.dart
│               ├── register_page.dart
│               ├── forgot_password_page.dart
│               ├── reset_password_page.dart
│               └── verify_otp_page.dart
├── shared/
│   └── widgets/
│       ├── titled_component.dart            # EXTENDED (US3): theme-aware "View All" link color
│       └── fields/
│           └── text_input_field.dart        # EXTENDED (US3): theme-aware label/hint colors
└── main.dart                                # UNCHANGED — already reads SettingsCubit.instance.isDarkMode for themeMode

assets/lang/
├── en.json                                  # EXTENDED: settings_dark_mode_option
└── ar.json                                  # EXTENDED: settings_dark_mode_option

test/
└── shared/
    └── bloc/
        └── settings_cubit_test.dart          # NEW (or extended): bloc_test coverage for dark-mode persistence/hydration
```

**Structure Decision**: Single Flutter project (existing `lib/` layer structure, no new top-level option). This feature is a pure extension of the existing `006-settings-screen` Settings tab and the pre-existing `SettingsCubit` — no new feature folder, no new screen, no new route.

## Complexity Tracking

*No entries — Constitution Check has no violations to justify.*
