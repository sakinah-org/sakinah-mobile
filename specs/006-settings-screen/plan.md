# Implementation Plan: Settings Screen

**Branch**: `006-settings-screen` | **Date**: 2026-08-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-settings-screen/spec.md`

## Summary

Add a Settings tab with two sections — an account section that switches between a guest prompt and an authenticated name/email card (both driven by the existing `SessionCubit`), and an options list (Prayer Times, Qibla Compass, Change Language, and — only when authenticated — Logout). Ship two new screens/sheets this list opens: a two-language (Arabic/English) bottom sheet that drives the existing `SettingsCubit`, and a new Qibla Compass screen (live rotating dial via `flutter_qiblah`, with a calibration prompt for low sensor accuracy and a static-degree fallback when no magnetometer is present). Both new UI surfaces pixel-match the imported Claude Design project ("Sakinah Quran App UI", screens §06 Language bottom sheet, §08 Settings, §10 Qibla Compass), reusing the app's existing `AppColors`/`AppTypography` tokens and icon set (`AppIcons.qibla`/`logOut`/`language`/`profile`/`chevronRight`) with no new design tokens needed.

## Technical Context

**Language/Version**: Dart (SDK `^3.5.3`), Flutter (stable channel matching `pubspec.yaml`)

**Primary Dependencies**: `flutter_bloc` (Cubits), `flutter_qiblah` (new — bearing + live heading), `geolocator` + `permission_handler` (existing, via `lib/handlers/location_handler.dart` / `permission_handler.dart`), `hive_flutter` via `SharedPrefHandler` (persistence), `supabase_flutter` (existing, via `SessionCubit` for logout), `flutter_svg` (icons)

**Storage**: Hive (`SharedPrefHandler`) — one new key (`AppPersistenceDataKeys.appLocale`); `SessionCubit.logout()` removes four existing keys it already owns. No SQL/remote schema changes.

**Testing**: `bloc_test` for the new/extended Cubit behavior (`SettingsCubit.setLocale/loadPersistedSettings`, `SessionCubit.logout`, `QiblaCompassCubit`), `mocktail` fakes for `QiblaRepository`, per Constitution Principle VIII (unit tests for new business logic; UI-only widget/page code not required to ship tests).

**Target Platform**: iOS + Android (Flutter mobile app). Qibla live-compass paths require a physical device — `flutter_qiblah` does not run on the iOS Simulator.

**Project Type**: Mobile app (single Flutter project, existing `lib/` layer structure — no new top-level option needed).

**Performance Goals**: Qibla dial responsive to device rotation within the ~3s budget in SC-003 (matches the sensor-stream's native update cadence — no polling/throttling introduced). Language switch and account-section updates are synchronous cubit `emit()`s — effectively instant (SC-002/SC-001).

**Constraints**: Two supported locales only (Arabic/English), matching `SettingsCubit`'s existing `supportedLocales`. No new backend/API surface — Qibla bearing is computed on-device (package + great-circle formula fallback), not fetched.

**Scale/Scope**: One new tab screen (Settings), one new bottom sheet (language), one new pushed screen (Qibla Compass) with 5 view states, 2 shared-Cubit extensions (`SettingsCubit`, `SessionCubit`), 1 new feature-local Cubit (`QiblaCompassCubit`) + repository.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design — still passes, no new violations introduced by the design artifacts below.*

| Principle | Check | Result |
|---|---|---|
| I. Feature-First, Complexity-Scaled Architecture | Settings is UI-only (`presentation/` only); Qibla gets the full Clean split because it has real domain logic (bearing/accuracy). Both checked against `lib/shared/bloc/` first — reuses `SessionCubit`/`SettingsCubit` rather than duplicating state (research.md R1/R2). | PASS |
| II. BLoC/Cubit State Management | No new state-management library. `SettingsCubit`/`SessionCubit` keep the existing singleton pattern; `QiblaCompassCubit` is intentionally *not* a singleton (per-screen state), with typed `[Feature][Status]State` classes justified by Qibla's genuinely distinct view branches (data-model.md §4), matching the `AyahOfTodayCubit`/`QuranFontSettingsCubit` precedent. | PASS |
| III. No Service-Locator DI | No `get_it`/`injectable` introduced; `QiblaRepositoryImpl` is constructed directly by `QiblaCompassCubit`, same as every other repository in the app. | PASS |
| IV. Centralized Design System | research.md R10: zero new colors/typography/icons required — everything maps onto existing `AppColors`/`AppTypography`/`AppIcons` tokens. | PASS |
| V. Reusable Widgets Over Inline Build Methods | Account-section guest/authenticated cards, option-tile rows, the logout confirmation dialog, the language sheet, and each Qibla view-state widget are all extracted as dedicated widget classes under `presentation/widgets/`, not inline `_buildX()` methods. | PASS |
| VI. Dio-Based Network Layer | Not applicable — this feature makes no network calls (Qibla bearing is on-device; Supabase sign-out goes through the `supabase_flutter` client already used by `SessionCubit`, not `DioClient`). | PASS (N/A) |
| VII. Configuration/Env/Localization | New persistence key added to `AppPersistenceDataKeys` (not a raw string); all new user-facing strings added to `TranslationKeys` + both `assets/lang/{en,ar}.json`, resolved via `translator.word(...)`. | PASS |
| VIII. Naming/Formatting/Test Discipline | New Cubit/state files follow `[Feature]Cubit`/`[Feature][Status]State`; `dart format` + `flutter analyze` before completion; `bloc_test` coverage for the new Cubit logic per Testing above. | PASS |

**New dependency justification** (Technology Stack & Dependencies section of the constitution): `flutter_qiblah` is a new package in a category (device compass/qibla-bearing) not currently covered by any existing dependency — adding it is a deliberate, in-scope decision for this feature (explicitly named in the feature's Logic section), not a duplicate of an already-approved package.

No entries needed in Complexity Tracking — no principle violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/006-settings-screen/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
├── contracts/             # Phase 1 output
│   ├── settings_cubit_contract.md
│   ├── session_cubit_logout_contract.md
│   └── qibla_repository_and_cubit_contract.md
└── tasks.md              # Phase 2 output (/speckit-tasks — not created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── shared/
│   └── bloc/
│       ├── settings_cubit.dart          # EXTENDED: setLocale(), loadPersistedSettings()
│       └── session_cubit.dart           # EXTENDED: logout()
├── configurations/
│   ├── app_persistence_data_keys.dart   # EXTENDED: appLocale key
│   └── app_translation_keys.dart        # EXTENDED: settings/language-sheet/qibla keys
├── navigation/
│   ├── app_routes.dart                  # EXTENDED: qiblaCompass route
│   └── route_generator.dart             # EXTENDED: case for QiblaCompassPage
├── features/
│   ├── main/ui/pages/main_page.dart     # EXTENDED: Settings tab placeholder → SettingsPage()
│   ├── settings/                        # NEW — UI-only feature
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── settings_page.dart
│   │       └── widgets/
│   │           ├── settings_authenticated_profile_card.dart
│   │           ├── settings_guest_prompt_card.dart
│   │           ├── settings_option_tile.dart
│   │           ├── settings_logout_confirmation_dialog.dart
│   │           └── language_bottom_sheet.dart
│   └── qibla/                           # NEW — business-logic feature
│       ├── domain/
│       │   ├── entities/
│       │   │   └── qibla_reading.dart   # QiblaReading / QiblaLiveReading / QiblaStaticReading / CompassAccuracy
│       │   └── repositories/
│       │       └── qibla_repository.dart
│       ├── data/
│       │   └── repositories/
│       │       └── qibla_repository_impl.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── qibla_compass_cubit.dart
│           │   └── qibla_compass_state.dart
│           ├── pages/
│           │   └── qibla_compass_page.dart
│           └── widgets/
│               ├── qibla_compass_dial.dart
│               ├── qibla_calibration_banner.dart
│               ├── qibla_static_bearing_view.dart
│               └── qibla_location_required_view.dart
assets/lang/{en,ar}.json                  # EXTENDED: new translation keys
pubspec.yaml                              # EXTENDED: flutter_qiblah dependency

test/
├── shared/bloc/settings_cubit_test.dart          # NEW
├── shared/bloc/session_cubit_logout_test.dart    # NEW
└── features/qibla/qibla_compass_cubit_test.dart  # NEW
```

**Structure Decision**: Single Flutter project (existing `lib/` layering, Constitution Principle I). `settings/` stays UI-only and reuses the two existing shared cubits; `qibla/` is a new top-level feature with the full Clean Architecture split because it owns real domain logic (bearing/accuracy computation), matching the `prayers`/`quran` precedent. No `contracts/` equivalent is needed in the shipped app (no external API surface for this feature) — the `contracts/` docs here describe internal Cubit/Repository contracts instead, consistent with how `specs/002-home-page` and `specs/003-prayers-times-screen` document both external-API and internal-Cubit contracts side by side.
