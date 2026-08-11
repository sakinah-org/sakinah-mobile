# Implementation Plan: Quran Fonts & Local Data Source Update

**Branch**: `005-quran-fonts-local-source` | **Date**: 2026-08-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-quran-fonts-local-source/spec.md`

## Summary

Two changes to the existing Quran feature (`specs/004-quran-screen`), both scoped to `lib/features/quran/data/` plus bundled assets — no domain or presentation-layer restructuring:

1. **Fonts**: `QuranFontSetting.availableFontFamilies` grows from 3 (`Lateef`, `Amiri`, `QPCHafs`) to 4 (`Amiri`, `Kitab`, `MeQuran`, `QPCHafs`); the default family becomes `QPCHafs`. All 4 font files are already bundled in `pubspec.yaml` — no new font sourcing needed.
2. **Data source**: `QuranRepositoryImpl` stops calling the remote Al Quran Cloud API for the Surah list, Juz grouping, and per-Surah reading content, and becomes fully local — sourced from `risan/quran-json`, split into one bundled JSON file per Surah (114 files, for per-Surah load performance) plus one combined list file covering both the Surah and Juz views. Since that source dataset carries no Juz-boundary data, one small supplementary static local table is added to preserve the existing Juz-grouping behavior. `QuranRepository`'s public interface is unchanged, so `QuranCubit`, `SurahReadingCubit`, and both page widgets need no changes.

## Technical Context

**Language/Version**: Dart (Flutter SDK `^3.5.3`, per constitution's Technology Stack)

**Primary Dependencies**: `hive_flutter` (via `SharedPrefHandler`, unchanged caching layer), `flutter/services` (`rootBundle`, for loading the new bundled JSON assets — same mechanism the old single-file fallback already used), `supabase_flutter` (unchanged, font-setting sync only). `dio`/`DioClient` is **removed** as a dependency of `QuranRepositoryImpl` specifically (no longer used by any of its three content methods) — `dio` itself remains part of the app for every other feature.

**Storage**: Hive (via `SharedPrefHandler`, unchanged keys/shapes) for caching; bundled JSON assets (`assets/quran/chapters/index.json`, `assets/quran/chapters/1.json`…`114.json`, `assets/quran/juz_boundaries.json`) as the sole source of truth for Surah/Juz/Ayah content; `public.user_preferences` (Supabase, unchanged) for authenticated font-setting sync.

**Testing**: `flutter_test` + `mocktail` + `bloc_test` (existing project convention, per constitution Principle VIII) — update `QuranRepositoryImpl`'s existing unit tests to reflect bundled-asset parsing instead of network+fallback branches.

**Target Platform**: iOS/Android via Flutter (existing mobile app, unchanged).

**Project Type**: Mobile app — single Flutter project, existing `lib/features/quran/` feature folder (business-logic feature, full Clean Architecture split per constitution Principle I) — this update only touches its `data/` layer plus one small `domain/entities/quran_font_setting.dart` literal-list change and one presentation-layer label-text fix (research.md R8).

**Performance Goals**: Surah list, Juz view, and any Surah's Reading screen load within ~1 second offline or online alike (spec.md SC-001); opening one Surah never loads another Surah's data, so per-Surah load time doesn't degrade as more Surahs are read in a session (SC-003).

**Constraints**: Zero network dependency for the Quran tab, Juz tab, and Surah Reading screen (spec.md FR-005) — this is now a hard constraint, not a fallback-only concern.

**Scale/Scope**: 114 Surahs, 30 Juz, 4 font families. Touches: `lib/features/quran/data/repositories/quran_repository_impl.dart`, `lib/features/quran/data/models/{surah_model,ayah_model}.dart`, `lib/features/quran/domain/entities/quran_font_setting.dart`, `lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart` (label text only), `assets/quran/**`, `pubspec.yaml`. Does not touch: `domain/entities/{surah,ayah,juz_section}.dart`, `domain/repositories/quran_repository.dart`, either Cubit, either page, or any other presentation widget.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Feature-First, Complexity-Scaled Architecture)**: PASS. Change stays entirely within `lib/features/quran/`'s existing Clean Architecture layers; no new cross-feature imports; the feature's layering depth is unchanged (still a full business-logic feature).
- **Principle II (BLoC/Cubit)**: PASS (no change) — `QuranCubit`, `SurahReadingCubit`, `QuranFontSettingsCubit` are untouched.
- **Principle III (No Service-Locator DI)**: PASS (no change) — `QuranRepositoryImpl`'s constructor DI pattern (optional named params defaulting to `.instance`) is preserved, just with the `dioClient` parameter removed since nothing in the class calls it anymore.
- **Principle IV (Centralized Design System)**: PASS — the 4 font family names are literal strings on `QuranFontSetting.availableFontFamilies`, matching the existing precedent (004 did the same for its 3); no new ad hoc color/spacing/icon literals introduced. New asset paths (`assets/quran/chapters/...`) follow the same pattern as the existing single bundled-asset path (a private constant inside the repository impl, not routed through `AppEndPoints`/`AppPersistenceDataKeys`, which are for network endpoints and Hive keys respectively — not local asset paths).
- **Principle V (Reusable Widgets)**: PASS (no change) — no new widget classes needed; the font-settings sheet's family iteration is already dynamic.
- **Principle VI (Dio-Based Network Layer)**: PASS — this feature *reduces* network usage (removes 3 of the repository's call sites); the one remaining network user in this feature (`_syncFontSettingToRemote`/`fetchRemoteFontSetting`, direct Supabase client calls) is unchanged and was already exempt from `DioClient` in 004 (Supabase's own client, not a `DioClient`-routed REST call — same precedent as `PrayerNotificationSettingsRepositoryImpl`).
- **Principle VII (Config/Env/Persistence keys)**: PASS — no new `AppEndPoints`/`AppPersistenceDataKeys`/`TranslationKeys` entries required (Hive keys are unchanged; the removed `quranCloudSurahList`/`quranCloudJuz`/`quranCloudSurah` endpoint constants on `AppEndPoints` become unused by this feature — left in place since `research.md R9` notes the Home screen's separate `Ayah of Today` feature uses a sibling endpoint on the same class, and pruning unused-by-this-feature constants is out of scope).
- **Principle VIII (Naming/Formatting/Tests)**: PASS — existing `QuranRepositoryImpl` unit tests are updated (not deleted) to match the new sourcing; `flutter format`/`flutter analyze` clean is still the bar.

No violations. Complexity Tracking table not needed.

*Post-Phase-1 re-check*: Unchanged — Phase 1 design (data-model.md, contracts/) introduced no new architectural elements beyond what Phase 0 already accounted for (one new bundled static table, one repository internals rewrite, one entity literal-list edit, one label-text edit). Gate still PASSES.

## Project Structure

### Documentation (this feature)

```text
specs/005-quran-fonts-local-source/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/            # Phase 1 output (/speckit-plan command)
│   ├── quran_repository_contract.md       # updated (data-source sourcing change)
│   └── quran_font_settings_contract.md    # updated (4-family note + migration)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

Note: `specs/004-quran-screen/contracts/quran_cubit_contract.md` and `surah_reading_cubit_contract.md` are **not** duplicated here — both Cubits' public APIs are entirely unchanged by this feature (research.md R5), so 004's originals remain the authoritative contract for them.

### Source Code (repository root)

Existing single-project Flutter app structure (`lib/`, `assets/`, `test/`), unchanged. This feature's touched paths:

```text
lib/features/quran/
├── data/
│   ├── models/
│   │   ├── surah_model.dart          # new fromJson mapping for chapters/index.json shape
│   │   └── ayah_model.dart           # new fromJson mapping for chapters/{n}.json shape
│   └── repositories/
│       └── quran_repository_impl.dart  # rewritten: bundled-asset sourcing, no DioClient (research.md R5)
├── domain/
│   └── entities/
│       └── quran_font_setting.dart   # availableFontFamilies (4) + new default (research.md R6)
└── presentation/
    └── widgets/
        └── quran_font_settings_sheet.dart  # _labelFor(...) text only (research.md R8)

assets/quran/
├── chapters/
│   ├── index.json                    # new — from risan/quran-json dist/chapters/en/index.json
│   └── 1.json … 114.json             # new — from risan/quran-json dist/chapters/{n}.json
├── juz_boundaries.json               # new — static 30-entry table (research.md R3)
└── quran_uthmani.json                # removed once the above are verified in place

pubspec.yaml                          # assets: entry swapped (research.md R4)
```

**Structure Decision**: No new top-level structure — this is a strict subset of the existing `specs/004-quran-screen` feature's own directory layout, touching only its data layer plus the two small entity/label edits noted above.

## Complexity Tracking

*No Constitution Check violations — table not needed.*
