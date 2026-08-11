# Implementation Plan: Quran Screen

**Branch**: `004-quran-screen` | **Date**: 2026-08-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-quran-screen/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Replace the two `Container()` placeholders that back the Quran tab and add a new pushed screen: `QuranPage` (Surah/Juz tabs, search, font-settings entry) and `SurahReadingPage` (continuous ayah rendering in the user's saved font). New business-logic feature `lib/features/quran/` with full Clean Architecture layering (own data fetching from the same Al Quran Cloud API family the Home screen's Ayah-of-Today already uses, plus a bundled local fallback), two feature-scoped Cubits per the brief's explicit request (`QuranCubit` for browsing+search, `SurahReadingCubit` for reading), and one feature-singleton Cubit (`QuranFontSettingsCubit`) shared by both screens for cross-screen font state. Font settings sync reuses the already-provisioned `public.user_preferences.quran_font_family`/`quran_font_size` columns — no new Supabase table needed. No new pub packages are required (`dio`, `hive_flutter`, `supabase_flutter` already cover every capability this feature needs). The design (`Sakinah Screens.dc.html`, imported live this session) confirms all three required Quran fonts (Lateef, Amiri, KFGQPC Nastaleeq) are already bundled and the font-settings trigger is a plain "Aa" text button, not a new icon (research.md R9/R10/R13) — the one remaining open gap is content, not code: a verified Quran-text dataset for the bundled offline fallback (research.md R4).

## Technical Context

**Language/Version**: Dart (SDK `^3.5.3`), Flutter (existing app)

**Primary Dependencies**: `flutter_bloc ^9.1.0` (new `QuranCubit`, `SurahReadingCubit`, `QuranFontSettingsCubit`), `dio ^5.7.0` via existing `DioClient.instance` (new Al Quran Cloud endpoints — research.md R1), `hive_flutter` via existing `SharedPrefHandler` (fetch-once-reuse-forever local cache — research.md R2), `supabase_flutter ^2.17.1` (direct `user_preferences` table access — research.md R8). **No new packages** — every dependency this feature needs is already in `pubspec.yaml`.

**Storage**: Hive (via `SharedPrefHandler`, four new keys — see data-model.md) as the permanent local cache and offline source of truth for Surah/Juz/Ayah content (static data, never invalidated once cached); Supabase Postgres `public.user_preferences` (already exists live, verified via schema query — not a new migration) for the two Quran font columns, additive/best-effort account sync exactly like the Prayers feature's existing pattern.

**Testing**: `flutter_test` + `bloc_test ^10.0.0` + `mocktail ^1.0.4` (already dev dependencies), mirroring `test/features/prayers/...`'s patterns; new tests live under `test/features/quran/...`.

**Target Platform**: iOS/Android via Flutter (existing app's supported platforms). No new platform-specific capabilities (unlike the Prayers feature's notification/geocoding additions) — this feature is pure data-fetch + render + local/remote preference sync.

**Project Type**: Mobile app (existing single Flutter app) — new feature module under `lib/features/quran/`, replacing the existing Quran-tab placeholder and adding one new pushed screen/route.

**Performance Goals**: Surah list visible within 2 seconds under normal network conditions, instantly from cache thereafter (SC-003); font changes visibly applied within 1 second of selection (SC-005); 114-row and 30-section lists scroll with no dropped frames (SC-002).

**Constraints**: Offline-capable after first successful load (fetch-once-reuse-forever local cache — research.md R2) with an explicit bundled-asset fallback when nothing is cached yet and the network is unavailable (FR-017/018, SC-008); search MUST NOT make any network call (FR-007); visual output MUST match the provided Sakinah design system reference (FR-019, SC-007) — design successfully imported this session (`Sakinah Screens.dc.html` §03–05 plus design-system tokens, research.md R10); implementation should build against those concrete reference points directly rather than treating this as unverifiable.

**Scale/Scope**: Two screens (`QuranPage`, `SurahReadingPage`), a fixed 114-Surah / 30-Juz dataset, no pagination.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment |
|---|---|
| I. Feature-First, Complexity-Scaled Architecture | **PASS.** This feature owns data fetching (three Al Quran Cloud endpoints + local cache + bundled fallback) and unique domain rules (Juz regrouping, search, font live-preview) → business-logic feature, full Clean split under `lib/features/quran/`. Checked `lib/shared/bloc/` first (Principle I step 1): no existing owner for Surah/Juz/Ayah/font-preference state, so this is genuinely new. `AppTypography.quranFontFamily`/`quranLight`/`quranDark` (existing shared design tokens) are reused as the base, not duplicated. |
| II. BLoC/Cubit State Management | **PASS.** Three Cubits, none a Bloc — matches "lists/settings toggles" guidance exactly. `QuranCubit`/`SurahReadingCubit` are feature-scoped (one consumer screen each, `BlocProvider`-created); `QuranFontSettingsCubit` is a singleton (`.instance`) because it's genuinely cross-screen within this feature (research.md R5) — same justification pattern as the constitution's own singleton criterion, scoped to the feature rather than promoted to `lib/shared/` since nothing outside `lib/features/quran/` reads it. All three use dedicated sealed state classes (data-model.md), following `PrayerTimesState`/`PrayerNotificationSettingsState`'s newer convention, not the legacy `AppStates` hierarchy. |
| III. No Service-Locator DI | **PASS.** `QuranRepositoryImpl` uses manual constructor DI (`DioClient.instance`, `SharedPrefHandler.instance!`), mirroring every existing repository impl. No `get_it`/`injectable`. |
| IV. Centralized Design System | **PASS.** Reuses `AppTypography.quranFontFamily`/`quranLight`/`quranDark` as the base Quran text style, overriding only `fontFamily`/`fontSize` per the user's `QuranFontSetting`. No new icon needed — the design's font-settings app-bar control is a plain "Aa" text button, not an SVG glyph (research.md R10/R13, corrected from an earlier assumption). The existing `AppIcons.search` icon is reused as-is. |
| V. Reusable Widgets Over Inline Build Methods | **PASS, planned.** Surah list tile, Juz section header, search field, font-settings bottom sheet, font-family preview card, and the ayah text view are each dedicated widget classes under `lib/features/quran/presentation/widgets/`, not inline `_build*` methods — see Project Structure below. |
| VI. Dio-Based Network Layer | **PASS.** All three new endpoints called via `DioClient.instance.request(RequestInstructions(...))`, mirroring `AyahRepositoryImpl` exactly (research.md R1) — no second `Dio` instance, no direct `dio.get()`. Errors normalized via `Failure.handleDioException`. |
| VII. Configuration/Env/Localization as Single Source of Truth | **PASS, with additions.** Three new `AppEndPoints` methods (research.md R1) plus one new table-name constant (`userPreferencesTable`, research.md R8 — none exists yet for this table). Four new `AppPersistenceDataKeys` entries (data-model.md). New user-facing strings (tab labels, search placeholder, font-settings sheet copy, unable-to-load/no-results states) added to `TranslationKeys` + both `assets/lang/en.json`/`ar.json`. The pre-existing hardcoded `"Quran"` bottom-nav label is fixed in the same change since this feature directly touches that tab (research.md R12) — the sibling `"Home"`/`"Settings"` labels are left alone, out of scope. |
| VIII. Naming, Formatting, Test Discipline | **PASS, planned.** `snake_case.dart` files, `PascalCase` classes, `[Feature]Cubit` naming (`QuranCubit`, `SurahReadingCubit`, `QuranFontSettingsCubit`). New unit tests planned for all three Cubits and the repository impl, mirroring `test/features/prayers/`'s existing `bloc_test`/`mocktail` structure. |

**New-dependency note**: None — unlike `003-prayers-times-screen`, this feature adds zero new pub packages. The one real remaining gap (a verified bundled Quran-text dataset — research.md R4) is a content-sourcing task, not an architectural addition, and is called out explicitly so `/speckit-tasks` tracks it as its own verifiable item rather than silently assuming it's solved by writing repository code. (The font-file and font-settings-icon gaps flagged in an earlier pass turned out not to exist — research.md R9/R13 — once the design was actually imported.)

**Design-fidelity status (FR-019/SC-007)**: Resolved for planning purposes — the design was successfully imported this session via the `DesignSync` tool (research.md R10), with concrete tokens, copy, and layout details now on record in research.md for `/speckit-implement` to build against directly.

No violations requiring justification — Complexity Tracking table below is empty.

**Post-Phase-1 re-check**: data-model.md and contracts/ (repository, both page-level Cubits, the font-settings singleton Cubit) were designed strictly within the boundaries assessed above — no new state-management pattern, no new DI mechanism, no new network layer, and every new string/asset/persistence-key/table-name goes through the existing centralized constants rather than being inlined. Constitution Check status: **unchanged, PASS.**

## Project Structure

### Documentation (this feature)

```text
specs/004-quran-screen/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/features/quran/                             # this feature — replaces the two Quran-tab placeholders
├── data/
│   ├── models/
│   │   ├── surah_model.dart                    # AlQuranCloud /surah (list) JSON (de)serialization + Hive envelope
│   │   ├── ayah_model.dart                     # AlQuranCloud /surah/{n} ayahs[] JSON (de)serialization
│   │   └── quran_font_setting_model.dart        # Hive scalars + Supabase row (de)serialization
│   └── repositories/
│       └── quran_repository_impl.dart           # see contracts/quran_repository_contract.md
├── domain/
│   ├── entities/
│   │   ├── surah.dart                           # see data-model.md
│   │   ├── ayah.dart
│   │   ├── juz_section.dart
│   │   └── quran_font_setting.dart
│   └── repositories/
│       └── quran_repository.dart                # abstract contract
└── presentation/
    ├── bloc/
    │   ├── quran_cubit.dart                     # see contracts/quran_cubit_contract.md
    │   ├── quran_state.dart
    │   ├── surah_reading_cubit.dart              # see contracts/surah_reading_cubit_contract.md
    │   ├── surah_reading_state.dart
    │   ├── quran_font_settings_cubit.dart         # see contracts/quran_font_settings_contract.md
    │   └── quran_font_settings_state.dart
    ├── pages/
    │   ├── quran_page.dart                       # REPLACES the Quran-tab placeholder in MainPage's PageView
    │   └── surah_reading_page.dart                # NEW pushed screen, new route
    └── widgets/
        ├── quran_tab_switcher.dart                # Surah / Juz segmented control
        ├── quran_search_field.dart
        ├── surah_list_tile.dart                   # number, Arabic name, transliteration, meaning, revelation type, ayah count
        ├── juz_section_header.dart
        ├── quran_unavailable_view.dart             # FR-018 explicit unable-to-load state (Quran tab + reading screen, shared)
        ├── quran_search_empty_view.dart             # FR-008/Edge Cases no-results state
        ├── ayah_text_view.dart                     # continuous ayat + numbered badges, styled from QuranFontSettingsCubit
        ├── quran_font_settings_sheet.dart           # bottom sheet: size control + 3-family selector
        └── quran_font_family_preview_card.dart      # one live-preview card per selectable family

lib/configurations/
├── app_end_points.dart                          # + quranCloudSurahList/quranCloudJuz/quranCloudSurah, + userPreferencesTable
├── app_persistence_data_keys.dart                # + quranSurahListCache, quranJuzSectionsCache, quranSurahCachePrefix,
│                                                  #   quranFontFamily, quranFontSize
└── app_translation_keys.dart                     # + new Quran-screen string keys (both en.json/ar.json)

lib/navigation/
├── app_routes.dart                                # + surahReading
└── route_generator.dart                           # + case AppRoutes.surahReading

lib/features/main/ui/pages/main_page.dart          # Container() at index 1 → const QuranPage()
lib/features/main/ui/widgets/main_bottom_navigation_bar.dart  # "Quran" label → TranslationKeys (research.md R12)

assets/
└── quran/quran_uthmani.json                       # NEW — bundled offline fallback dataset (research.md R4, content task)
                                                     # (no new font files needed — Lateef/Amiri/Nastaleeq already bundled, research.md R9)

test/features/quran/                               # mirrors lib/features/quran/ 1:1
├── presentation/bloc/quran_cubit_test.dart
├── presentation/bloc/surah_reading_cubit_test.dart
├── presentation/bloc/quran_font_settings_cubit_test.dart
└── data/repositories/quran_repository_impl_test.dart
```

**Structure Decision**: Standard existing-app "business-logic feature" layout (Constitution Principle I), added under `lib/features/quran/` alongside the app's other features (`auth`, `home`, `prayers`, `main`) — both the browsing screen and the reading screen live in this one feature folder rather than being split into two, since they share the same repository/entities and splitting would force a cross-feature import (disallowed by Principle I). No new top-level project/package — this is a single Flutter app, so Option 1/2/3 templates from the base plan template don't apply as-is; the tree above is the concrete equivalent, following `003-prayers-times-screen`'s precedent for documenting it this way.

## Complexity Tracking

*No Constitution Check violations — table intentionally empty.*
