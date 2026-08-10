# Implementation Plan: Prayers Times Screen

**Branch**: `003-prayers-times-screen` | **Date**: 2026-08-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-prayers-times-screen/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Replace the existing `PrayersPage` placeholder with the real Prayers Times screen: a location card (city/country/calculation method/Hijri date) plus five per-prayer rows (name, time, fixed "10 minutes before" caption, on/off toggle), an all-off alert banner, and notification-permission guidance cards. Reuses the existing shared `lib/shared/prayer_times/` module (`PrayerTimesCubit.instance`) unchanged for times/location, and adds one new business-logic feature layer (`lib/features/prayers/`) owning per-prayer notification-toggle state, local persistence, Supabase sync (local-first, last-write-wins), and local reminder scheduling. Notification delivery and city/country display both require new capabilities the codebase doesn't have yet (`flutter_local_notifications`+`timezone` for scheduling; `geocoding` for reverse-geocoding coordinates) — see research.md R1/R3.

## Technical Context

**Language/Version**: Dart (SDK `^3.5.3`), Flutter (existing app)

**Primary Dependencies**: `flutter_bloc ^9.1.0` (new `PrayerNotificationSettingsCubit`), `hive_flutter` via existing `SharedPrefHandler` (local persistence), `supabase_flutter ^2.17.1` (direct table access, new for this feature — first non-auth Supabase table usage in the codebase), `permission_handler ^11.3.1` (extended with a new notification-status method), `hijri ^3.0.0` + existing `date_time_extensions.dart` (Hijri date, reused as-is), `flutter_svg` (icons, reused). **New packages to add**: `flutter_local_notifications` + `timezone` (local reminder scheduling — research.md R3), `geocoding` (city/country reverse geocoding — research.md R1). No `firebase_messaging`/Firebase push in v1 (research.md R3 — no backend scheduler exists to originate it).

**Storage**: Hive (via `SharedPrefHandler`, new key `AppPersistenceDataKeys.prayerNotificationSettings`) as the local-first source of truth; Supabase Postgres `public.prayer_notification_settings` (already migrated, RLS-scoped) as the additive, best-effort account-sync target — see data-model.md and contracts/supabase_sync_contract.md.

**Testing**: `flutter_test` + `bloc_test ^10.0.0` + `mocktail ^1.0.4` (all already dev dependencies), mirroring `test/shared/prayer_times/prayer_times_cubit_test.dart` and `prayer_times_repository_impl_test.dart`'s patterns; new tests live under `test/features/prayers/...`.

**Target Platform**: iOS/Android via Flutter (existing app's supported platforms). Local notification scheduling has platform-specific follow-ups (Android 13+ `POST_NOTIFICATIONS`, exact-alarm permission on newer Android, iOS notification capability) — flagged in research.md R3, addressed at the task/implementation level, not a plan blocker.

**Project Type**: Mobile app (existing single Flutter app) — new feature module under `lib/features/prayers/`, extending the existing placeholder in place.

**Performance Goals**: Screen visible with all five prayer times within 2 seconds of opening (SC-001); toggle state updates optimistically/immediately in the UI (SC-002/SC-003), with no perceptible delay before local persistence — network/Supabase sync happens fully in the background.

**Constraints**: Offline-capable (prayer times and notification toggles both usable with no connectivity — times via existing fallback cache, toggles via local-first Hive); Supabase sync MUST be fire-and-forget/non-blocking and MUST NOT roll back local state on failure (FR-006, FR-007); visual output MUST pixel-match the provided Sakinah design system reference (FR-019, SC-007).

**Scale/Scope**: One screen (`PrayersPage`, replacing the existing placeholder), fixed set of exactly five prayers, no pagination or large lists.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment |
|---|---|
| I. Feature-First, Complexity-Scaled Architecture | **PASS.** This feature owns data fetching (Supabase sync), multi-step flows (permission gating, last-write-wins reconciliation), and unique domain rules (reminder scheduling, all-off banner) → qualifies as a business-logic feature, full Clean split (`data/`, `domain/`, `presentation/`) under `lib/features/prayers/`. Checked `lib/shared/bloc/` first (Principle I step 1, research.md R7): no existing owner for per-prayer notification-toggle state, so this is genuinely new state, not a duplicate. Prayer times/location remain owned by `lib/shared/prayer_times/` and are only consumed via `PrayerTimesCubit.instance`, never re-fetched or duplicated. |
| II. BLoC/Cubit State Management | **PASS.** New `PrayerNotificationSettingsCubit` — a Cubit, matching the constitution's own "settings toggles" example. Feature-scoped via `BlocProvider` at `PrayersPage`, not a singleton (unlike the existing global `PrayerTimesCubit`/`SettingsCubit`/`SessionCubit`), since this state has exactly one screen-level consumer. Uses a dedicated sealed state class (`PrayerNotificationSettingsState`), following `PrayerTimesState`'s newer convention rather than the legacy `AppStates` hierarchy. |
| III. No Service-Locator DI | **PASS.** Repository constructed with manual constructor DI (mirrors `PrayerTimesRepositoryImpl`'s pattern: `SharedPrefHandler.instance`, `Supabase.instance.client`, `PermissionHandler()`). No `get_it`/`injectable` introduced. |
| IV. Centralized Design System | **PASS, with additions planned correctly.** New icon(s) (e.g. an alert/warning glyph for the banner; toggle affordance likely a styled `Switch`/`CupertinoSwitch` using `AppColors` tokens, not a new SVG) go through `AppIcons`/`assets/icons/` registration before use, per the existing pattern — no inline asset path strings. No new color/typography tokens expected beyond composing existing `AppColors`/`AppTypography`; confirmed/adjusted during design import for pixel-match (FR-019). |
| V. Reusable Widgets Over Inline Build Methods | **PASS.** Location card, per-prayer row, all-off banner, and both permission-guidance cards are each dedicated widget classes under `lib/features/prayers/presentation/widgets/`, not inline `_build*` methods on the page. |
| VI. Dio-Based Network Layer | **PASS / N/A for new calls.** This feature adds no new Dio/HTTP calls — prayer-time fetching remains entirely inside the existing shared module. The one new network surface (Supabase table access) goes through the Supabase client directly, matching the codebase's only existing precedent (`auth_repository_impl.dart`'s direct `Supabase.instance.client.auth` calls) — not a `DioClient` concern. |
| VII. Configuration/Env/Localization as Single Source of Truth | **PASS, with one addition.** New Hive key added to `AppPersistenceDataKeys` (not inlined); new Supabase table name added as a constant on `AppEndPoints` rather than an inline string literal (research.md R6); new user-facing strings (permission help/denied text, all-off banner text) added to `TranslationKeys` + both `assets/lang/en.json`/`ar.json` — no hardcoded UI strings. |
| VIII. Naming, Formatting, Test Discipline | **PASS.** `snake_case.dart` files, `PascalCase` classes, `[Feature]Cubit`/`[Feature][Status]State` naming. New unit tests for the Cubit and repository impl planned (mirroring existing `bloc_test`/`mocktail` templates), consistent with "new business logic SHOULD ship with a unit test." |

**New-dependency note** (not a violation): `flutter_local_notifications`, `timezone`, and `geocoding` are additions in categories the current "Technology Stack & Dependencies" section doesn't yet cover (no existing notification-scheduling or geocoding package) — this is an addition, not a departure from an existing decision, so no Complexity Tracking entry is required. Worth reflecting in a future constitution amendment, but that is out of scope for this plan.

No violations requiring justification — Complexity Tracking table below is empty.

**Post-Phase-1 re-check**: data-model.md and contracts/ (cubit, Supabase sync, notification scheduling) were designed strictly within the boundaries assessed above — no new state-management pattern, no new DI mechanism, no new network layer, and no inline strings/assets were introduced beyond what's already itemized (Principle VII additions) and planned as proper widget classes (Principle V). Constitution Check status: **unchanged, PASS.**

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/features/prayers/                          # this feature — replaces the existing placeholder
├── data/
│   ├── models/
│   │   └── prayer_notification_setting_model.dart   # Hive envelope + Supabase row (de)serialization
│   └── repositories/
│       └── prayer_notification_settings_repository_impl.dart  # see contracts/supabase_sync_contract.md
├── domain/
│   ├── entities/
│   │   └── prayer_reminder_setting.dart              # see data-model.md
│   └── repositories/
│       └── prayer_notification_settings_repository.dart        # abstract contract
└── presentation/
    ├── bloc/
    │   ├── prayer_notification_settings_cubit.dart    # see contracts/prayer_notification_settings_cubit_contract.md
    │   └── prayer_notification_settings_state.dart
    ├── pages/
    │   └── prayers_page.dart                # REPLACES the existing placeholder body; route unchanged
    └── widgets/
        ├── prayer_location_card.dart
        ├── prayer_reminder_tile.dart
        ├── prayer_reminders_off_banner.dart
        ├── notification_permission_help_card.dart
        └── notification_permission_permanently_denied_card.dart

lib/handlers/
└── notification_handler.dart                 # NEW — see contracts/notification_scheduling_contract.md

lib/shared/prayer_times/                      # EXISTING — reused as-is, one addition:
└── data/repositories/prayer_times_repository_impl.dart
    # + resolveDisplayLocation() method (research.md R1); domain interface gains the matching
    #   abstract method in prayer_times_repository.dart

lib/handlers/permission_handler.dart          # EXISTING — one addition:
    # + checkNotificationPermissionStatus() (research.md R4), existing methods unchanged

lib/configurations/
├── app_persistence_data_keys.dart            # + prayerNotificationSettings key
├── app_end_points.dart                       # + prayerNotificationSettingsTable constant
└── app_translation_keys.dart                 # + new Prayers-screen string keys (both en.json/ar.json)

lib/utils/assets/app_icons_keys.dart          # + any new icon key(s) needed (e.g. alert glyph)

test/features/prayers/                        # mirrors lib/features/prayers/ 1:1
├── presentation/bloc/prayer_notification_settings_cubit_test.dart
└── data/repositories/prayer_notification_settings_repository_impl_test.dart
```

**Structure Decision**: Standard existing-app "business-logic feature" layout (Constitution Principle I), added under `lib/features/prayers/` alongside the app's other features (`auth`, `home`, `main`). No new top-level project/package — this is a single Flutter app, not a multi-project repo, so Option 1/2/3 templates above don't apply as-is; the tree shown is the concrete equivalent. The existing placeholder page and its already-wired route (`AppRoutes.prayers` in `lib/navigation/route_generator.dart`) are reused, not duplicated (research.md R8).

## Complexity Tracking

*No Constitution Check violations — table intentionally empty.*
