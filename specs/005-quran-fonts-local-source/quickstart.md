# Quickstart: Validating the Quran Fonts & Local Data Source Update

## Prerequisites

- No new packages to install — this feature only adds bundled JSON assets and font files already registered in `pubspec.yaml` (`flutter pub get` only if the branch hasn't been fetched yet).
- The new bundled dataset (`assets/quran/chapters/index.json`, `assets/quran/chapters/1.json`…`114.json`, `assets/quran/juz_boundaries.json` — research.md R2–R4) must be in place and registered in `pubspec.yaml` before any scenario below is meaningful; these are explicit `/speckit-tasks` items, not assumed complete.
- A pre-update install (or a manually seeded Hive value of `quran_font_family = 'Lateef'`) is useful for Scenario 4 (migration); a fresh install is fine for everything else.
- Signed-out (guest) and signed-in test accounts both available, to re-verify font-sync still works (unchanged behavior).
- Run the app: `flutter run`.

## Scenario 1 — Full offline reliability (User Story 1, P1)

1. Fresh-install the app (or clear its storage) **with the device in airplane mode from the very first launch** — no prior cache exists.
2. Open the Quran tab.
3. **Expect**: all 114 Surahs load and display (number, Arabic name, transliteration, meaning, revelation type, ayah count) — instantly, with no loading spinner tied to a network wait, and no "unable to load" state (spec.md FR-003/FR-005).
4. Switch to the Juz tab.
5. **Expect**: all 30 Juz sections appear immediately with the correct Surahs grouped beneath each, still offline.
6. Open several different Surahs' Reading screens in a row, including ones you haven't opened before this session.
7. **Expect**: each opens with readable ayat with no perceptible delay, regardless of order or which was opened first (SC-003 — per-Surah files mean no Surah's load time depends on any other Surah having been read already).
8. Turn network connectivity back on and repeat steps 2–6.
9. **Expect**: byte-for-byte identical results to the offline pass (SC-002) — connectivity makes no observable difference, because nothing here ever depended on it.

## Scenario 2 — A Surah spanning multiple Juz still groups correctly (User Story 1, P1 — regression check)

1. On the Juz tab, locate a Surah known to span multiple Juz (e.g. Al-Baqarah, which spans Juz 1–3).
2. **Expect**: it appears under every Juz section it has ayat in, computed from the new static Juz-boundary table (research.md R3) rather than the old per-ayah `juz` field — same visible result as before this update (spec.md FR-004, unchanged).
3. Compare that Surah's displayed fields (name, transliteration, meaning, revelation type, ayah count) under two different Juz headers.
4. **Expect**: identical on both — Juz view only changes grouping, not the underlying per-Surah facts (unchanged from spec 004).

## Scenario 3 — 4 selectable Quran fonts (User Story 2, P2)

1. From the Quran tab's app bar, open the font-settings bottom sheet.
2. **Expect**: exactly 4 font family cards — Amiri, Kitab, Me Quran, QPC Hafs — each with its own live preview of sample Quran text (spec.md FR-001/FR-002).
3. Select each of the 4 in turn.
4. **Expect**: the live-rendered Quran text (in the sheet's preview and, if a Surah Reading screen is open behind it, the ayat themselves) updates immediately to each selected family (FR-014, unchanged behavior).
5. Restart the app.
6. **Expect**: the last-selected family (one of the 4) is still applied (FR-015, unchanged).

## Scenario 4 — Migrating a stale, no-longer-offered font family (User Story 2, P2 — new)

1. On a device/install with `quran_font_family` previously saved as `'Lateef'` (the old default, no longer in the 4-family set) — either a genuine pre-update install, or manually seed this Hive value before launching.
2. Open the Quran tab or Surah Reading screen.
3. **Expect**: Quran text renders in the new default family (`QPCHafs`), not a crash, blank text, or the now-invalid `'Lateef'` value — and no error is shown to the user (spec.md FR-006, research.md R7).
4. Open the font-settings sheet.
5. **Expect**: `QPCHafs`'s card shows as the currently-selected one (the migration was persisted, not just applied in memory for this session).
6. If signed in, verify the corrected value was also written to `user_preferences` (`select quran_font_family from user_preferences where user_id = ...` in the Supabase SQL editor) rather than leaving the stale value there for a second device to pick up.

## Scenario 5 — Search, reading layout, and font sync are unaffected (regression check)

1. Repeat spec 004's Scenario 4 (search by Arabic name/transliteration, no-results state, meaning is not searched) and Scenario 5 steps 13–16 (cross-device font sync, guest-local-only) exactly as documented in `specs/004-quran-screen/quickstart.md`.
2. **Expect**: identical behavior to before this update in every respect other than the font family names/count and the data now being sourced locally.

## Automated checks to run before calling this feature done

- `flutter analyze` — clean, no new lints.
- `flutter test test/features/quran/` — update existing `QuranRepositoryImpl` tests to assert bundled-asset parsing (no `DioClient` mock/call expected anymore) instead of network + fallback branches; add coverage for: per-Surah file isolation (opening Surah N never reads another Surah's file), Juz-boundary-table-based grouping (including a multi-Juz Surah), the `meaning` field surviving the `chapters/en/index.json` source switch, the 4-family list, the new default, and the stale-family migration (both local-only and local+remote paths).
- Manual side-by-side comparison against the design reference for the font-settings sheet with 4 cards instead of 3, confirming no layout breakage from the extra card (spec.md FR-009/SC's visual-parity intent, carried over from 004 SC-007) — flagged as not verifiable during planning, complete at implementation time.
