# Implementation Plan: Home Page (Prayer Times & Ayah of Today)

**Branch**: `002-home-page` | **Date**: 2026-08-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-home-page/spec.md`

## Summary

Build the app's Home tab as the first screen of `MainPage`'s bottom navigation, composed of a day/Hijri-date header with a time-of-day greeting, a next-prayer countdown card with a condensed 5-prayer strip, and an "Ayah of Today" card. Prayer times are served by a new **global, singleton `PrayerTimesCubit`** living in a shared `lib/shared/prayer_times/` module (data + domain layers, reused later by a separate Prayers settings feature) that calls the AlAdhan API through the existing `DioClient`, resolves location via device geolocation (new `LocationHandler`), and falls back to the last successfully cached response. The Ayah of Today is served by a **Home-scoped `AyahOfTodayCubit`** (own `lib/features/home/{data,domain,presentation}` layers) that calls the Al Quran Cloud API once per calendar day, caches the result via `SharedPrefHandler`, and falls back to the last cached ayah (labeled) or an explicit unavailable/retry state. UI pixel-matches the "Home" screen (light + dark, RTL Arabic primary + LTR English secondary) read directly from the Sakinah Claude Design project, whose color/typography tokens already exist 1:1 in `lib/utils/style/`.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.5.3` (per `pubspec.yaml`/constitution)

**Primary Dependencies**: `flutter_bloc ^9.1.0` (Cubit), `dio ^5.7.0` (via `DioClient.instance`), `hive_flutter ^1.1.0` (via `SharedPrefHandler`), `flutter_svg` (icons) — all existing. **New**: `geolocator` (device coordinates for prayer-location auto-detect), `hijri` (Gregorian→Hijri conversion for the header date, computed client-side since the AlAdhan response's `hijri` field is explicitly out of scope per the integration reference), `share_plus` (native share sheet for the Ayah card's "Share" action, which is a live, wired control in the design mock, not decorative).

**Storage**: Hive via `SharedPrefHandler` singleton (existing pattern) — new keys for: last-detected prayer location (lat/lng), selected calculation method, last successful prayer-times response (single-slot cache), and the Ayah-of-Today cache (ayah + fetch date, single-slot).

**Testing**: `bloc_test` + `mocktail` (existing dev deps) for `PrayerTimesCubit`/`AyahOfTodayCubit` state transitions and repository fallback/cache logic; no widget-test requirement beyond what the constitution already asks for UI-only changes.

**Target Platform**: iOS + Android via Flutter (existing app). Adds platform location-permission strings (`NSLocationWhenInUseUsageDescription` on iOS; `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION` on Android) required by `geolocator`.

**Project Type**: Mobile app (single Flutter project, existing `lib/` layout — no new top-level project).

**Performance Goals**: Home's first paint must not block on network — render cached/loading state immediately (`ShimmerContainer`) while `PrayerTimesCubit`/`AyahOfTodayCubit` resolve; countdown re-renders once per second without jank (target 60fps, no full-card rebuild — only the countdown text region).

**Constraints**: Fully offline-capable per spec (FR-007/008/013/014); pixel parity across 2 locales (ar/en, RTL/LTR mirrored) × 2 themes (light/dark) per FR-018/SC-008; ayah text length is unbounded within a Quranic verse's realistic range and must not break layout (FR-015/SC-006).

**Scale/Scope**: One new page (`HomePage`) wired as tab index 0 of the existing 3-tab `MainPage`; one new shared cross-feature module (`lib/shared/prayer_times/`); one new business-logic feature module (`lib/features/home/`) for the Ayah of Today; ~6 new presentation widgets; no backend/schema changes (both APIs are unauthenticated public REST endpoints).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design — see "Post-Design Re-check" below.*

| Principle | Check | Status |
|---|---|---|
| I. Feature-First, Complexity-Scaled | `lib/shared/bloc/` and `lib/shared/models/` checked first — no existing owner for prayer times, ayah, or Hijri-date logic. Prayer Times gets full `data/domain` layering in `lib/shared/prayer_times/` (real network + cache + multi-feature reuse = genuine business logic, and the user explicitly asked for this shared placement). Ayah of Today gets full Clean Architecture layering scoped to `lib/features/home/` (real fetch/cache/fallback chain = genuine business logic, single consumer so it stays feature-local, not shared). No `usecases/` layer added for either — each has exactly one meaningful operation, so a use-case indirection would be pure ceremony per the "scale layering to actual complexity" rule. | PASS |
| II. BLoC/Cubit | `PrayerTimesCubit` follows the `SettingsCubit`/`UserCubit`/`SessionCubit` singleton pattern (private constructor + `static instance`) because it's genuinely cross-feature (Home now, Prayers settings later, a future notification scheduler listens to it per the integration reference). `AyahOfTodayCubit` is an ordinary, non-singleton `Cubit`, provided via `BlocProvider` at `HomePage` only — single consumer, so no singleton. Both use dedicated `[Feature][Status]State` classes (not generic `AppStates`) because each needs richer payloads (`times` + `nextPrayer` + `isStale`; `ayah` + `isCached`) than `LoadedState(dynamic)` cleanly expresses. | PASS |
| III. No Service-Locator DI | Repositories are constructed with manually-passed `DioClient.instance` / `SharedPrefHandler.instance!` / a new `LocationHandler()` instance — no `get_it`. | PASS |
| IV. Centralized Design System | Spot-checked the design system's `tokens/colors.css` against `lib/utils/style/app_colors.dart` — exact hex parity already exists (teal/neutral palette, light/dark semantic pairs, `success`/`warning`/`error`/`info`). No new colors needed. One new icon asset needed (`quote` mark on the Ayah card) — added to `AppIcons` + `assets/icons/quote.svg` before use, per the existing pattern. | PASS |
| V. Reusable Widgets | Home page composed from dedicated widget classes (`HomeGreetingHeader`, `PrayerTimesCard`, `PrayerDayStrip`, `AyahOfTodayCard`, plus unavailable/retry variants) under `lib/features/home/presentation/widgets/` — no inline `_build*` methods on the page. New device-interaction code (geolocation) goes in `lib/handlers/location_handler.dart`, following the existing `ImagePickerHandler`/`PermissionHandler` pattern. | PASS |
| VI. Dio Network Layer | Both AlAdhan and Al Quran Cloud calls go through `DioClient.instance.request(RequestInstructions(...))`. Since these are third-party hosts distinct from the app's own `AppEnv.baseUrl`, `RequestInstructions.url` carries the full absolute URL — Dio uses an absolute URL as-is regardless of the client's configured `baseUrl`, so no second `Dio` instance is created. Errors normalized through `Failure.handleDioException`. | PASS |
| VII. Config/Env/Localization | New `AppEndPoints` constants for the two external base URLs (deliberately *not* added to `AppEnv`, since `AppEnv` models the app's own backend environment/security config, not fixed public third-party hosts — see research.md). New `AppPersistenceDataKeys` entries for location/method/caches — no ad hoc Hive keys. All new UI copy (greeting, prayer labels, "Next prayer", "until adhan", "Verse of the Day"/Ayah of Today heading, "Share", "Cached", "Retry", unavailable/guidance messages) added to `TranslationKeys` + `assets/lang/en.json` + `assets/lang/ar.json`, consumed via `translator.word(...)` — no hardcoded UI strings. | PASS |
| VIII. Naming/Format/Test | `PrayerTimesCubit`/`AyahOfTodayCubit` naming; states as `[Feature][Status]State`; `snake_case.dart` files. New Cubit logic and repository fallback/cache logic ship with `bloc_test`/`mocktail` unit tests. `dart format` + `flutter analyze` clean before done. | PASS |

**Directly-touched inconsistency fixed in this change**: `MainPage`'s `PageView` currently has 5 placeholder `Container()` children against a 3-item bottom nav bar (a leftover from the earlier nav-bar reduction commit). Since this feature adds the first real tab, the `PageView` children list is trimmed to 3 (Home, Quran-placeholder, Settings-placeholder) per Governance's "fix it in the same change if it's directly touched" rule.

**New dependencies note**: `geolocator`, `hijri`, `share_plus` are each a new package category (no existing package in the approved stack covers device geolocation, Hijri calendar math, or native share) — each is single-purpose, actively maintained, and directly required by an explicit spec requirement (FR-003 location, FR-002 Hijri date, the design's wired Share control). Not a Principle violation; flagged here for visibility per "adding a new package... requires a reason."

## Project Structure

### Documentation (this feature)

```text
specs/002-home-page/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── prayer_times_api.md
│   ├── ayah_of_today_api.md
│   ├── prayer_times_cubit_contract.md
│   └── ayah_of_today_cubit_contract.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
lib/
├── configurations/
│   ├── app_end_points.dart          # + AlAdhan / Al Quran Cloud base URLs
│   └── app_persistence_data_keys.dart # + location/method/cache keys
├── handlers/
│   └── location_handler.dart        # NEW — geolocator wrapper (device coordinates)
├── navigation/
│   ├── app_routes.dart              # + AppRoutes.prayers (placeholder target)
│   └── route_generator.dart         # + case for AppRoutes.prayers
├── toolkit/
│   └── extensions/
│       └── date_time_extensions.dart # + Hijri-date + greeting-period helpers
├── utils/
│   └── assets/
│       └── app_icons_keys.dart      # + AppIcons.quote
├── shared/
│   ├── bloc/                        # (unchanged — PrayerTimesCubit lives with its module, see below)
│   └── prayer_times/                # NEW shared module (reused by a future Prayers feature)
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── prayer_times.dart          # PrayerTimes (5 named DateTimes + date)
│       │   │   ├── prayer_location.dart       # PrayerLocation union: Coordinates | City
│       │   │   └── calculation_method.dart    # CalculationMethod enum + AlAdhan id mapping
│       │   └── repositories/
│       │       └── prayer_times_repository.dart   # abstract
│       ├── data/
│       │   ├── models/
│       │   │   └── prayer_times_model.dart    # AlAdhan JSON <-> PrayerTimes, cache envelope
│       │   └── repositories/
│       │       └── prayer_times_repository_impl.dart
│       └── presentation/
│           └── bloc/
│               ├── prayer_times_cubit.dart    # singleton: PrayerTimesCubit.instance
│               └── prayer_times_state.dart
└── features/
    └── home/                         # NEW feature (Ayah of Today owns data/domain; page composes both)
        ├── data/
        │   ├── models/
        │   │   └── ayah_of_today_model.dart   # Al Quran Cloud JSON <-> AyahOfToday, cache envelope
        │   └── repositories/
        │       └── ayah_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── ayah_of_today.dart
        │   └── repositories/
        │       └── ayah_repository.dart        # abstract
        └── presentation/
            ├── bloc/
            │   ├── ayah_of_today_cubit.dart     # scoped (not singleton), provided at HomePage
            │   └── ayah_of_today_state.dart
            ├── pages/
            │   └── home_page.dart
            └── widgets/
                ├── home_greeting_header.dart          # greeting + day name + Hijri date
                ├── prayer_times_card.dart              # gradient card: next prayer + countdown + edit icon
                ├── prayer_times_countdown.dart         # the ticking h:mm:ss text (isolated for rebuild scope)
                ├── prayer_day_strip.dart               # 5-prayer condensed row
                ├── prayer_times_unavailable_view.dart  # FR-008/FR-009 states
                ├── ayah_of_today_card.dart             # ayah card + share + "Cached" badge
                └── ayah_of_today_unavailable_view.dart # FR-014 unavailable+retry state

lib/features/main/ui/pages/main_page.dart   # PageView index 0 -> HomePage(); trim to 3 children
lib/main.dart                                # + BlocProvider(PrayerTimesCubit.instance) at root

assets/icons/quote.svg                       # NEW — decorative quote mark on the Ayah card
assets/lang/en.json, assets/lang/ar.json     # + new TranslationKeys entries
lib/configurations/app_translation_keys.dart # + new keys

test/shared/prayer_times/...                 # PrayerTimesCubit + repository unit tests
test/features/home/...                       # AyahOfTodayCubit + repository unit tests
```

**Structure Decision**: Single Flutter mobile app (existing `lib/` layout, no new top-level project). Prayer Times is a **shared, business-logic module** under `lib/shared/prayer_times/` (full `domain`/`data`/`presentation` split, singleton Cubit) because it is explicitly cross-feature (Home today, Prayers settings later, a future notification scheduler). The Ayah of Today is a **business-logic feature** under `lib/features/home/` (full `data`/`domain`/`presentation` split) because it owns real fetch/cache/fallback logic but has exactly one consumer (Home) today. `HomePage` itself is presentation-only composition — it does not duplicate either Cubit's logic, it only subscribes to `PrayerTimesCubit.instance` (via root `BlocProvider`) and a locally-provided `AyahOfTodayCubit`.

## Post-Design Re-check

*Re-evaluated after Phase 1 (`data-model.md`, `contracts/`, `quickstart.md`) — no changes to the Constitution Check verdicts above.*

- `data-model.md`'s `PrayerLocation`/`CalculationMethod`/`PrayerTimes` and `AyahOfToday` entities stayed within a single repository method each (Principle I) — no use-case layer was introduced during design.
- `contracts/prayer_times_cubit_contract.md` confirms `PrayerTimesCubit` stays a singleton with typed states (Principle II); `contracts/ayah_of_today_cubit_contract.md` confirms `AyahOfTodayCubit` stays scoped, non-singleton.
- Both contract docs confirm all network access flows through the two repository methods only, which in turn go through `DioClient.instance` (Principle VI) — no direct `Dio`/`http` calls introduced by any widget or Cubit.
- `quickstart.md`'s automated-coverage section confirms both Cubits and both repositories get `bloc_test`/`mocktail` unit tests (Principle VIII).
- No new Constitution violations surfaced during design; the three new dependencies remain the only flagged additions (see "New dependencies note" above), unchanged in count or scope.

**Gate status: PASS.** Proceeding to `/speckit-tasks` is unblocked.

## Complexity Tracking

*No unjustified Constitution violations — table intentionally empty. The three new dependencies (`geolocator`, `hijri`, `share_plus`) are documented above under "New dependencies note" rather than here, since each is additive (new capability category) rather than a deviation from an existing rule.*
