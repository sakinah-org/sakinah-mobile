# Quickstart: Validating the Quran Screen

## Prerequisites

- No new packages to install — `dio`, `hive_flutter`, and `supabase_flutter` already cover this feature's needs (`flutter pub get` only if the branch hasn't been fetched yet).
- The bundled offline-fallback dataset (`assets/quran/quran_uthmani.json`, research.md R4) and the third Quran font file (research.md R9) must be in place before offline/font-family scenarios below are meaningful — both are tracked as explicit `/speckit-tasks` items, not assumed complete.
- Signed out (guest) and signed-in test accounts both available, to exercise font-sync scenarios.
- Run the app: `flutter run`.

## Reaching the screens

Quran tab: bottom navigation, second tab (index 1). Surah Reading screen: tap any Surah card from either tab or from search results; during development, push directly via `Navigator.pushNamed(context, AppRoutes.surahReading, arguments: <surahNumber>)`.

## Scenario 1 — Browse all Surahs in order (User Story 1, P1)

1. Open the Quran tab.
2. **Expect**: the Surah tab is shown by default; all 114 Surahs list in order 1–114, each showing number, Arabic name, transliteration, meaning, revelation type, and ayah count.
3. Scroll to the bottom.
4. **Expect**: smooth scrolling, Surah 114 (An-Nas) is the last entry, no duplicates or gaps.
5. Force-quit and reopen the app (still online).
6. **Expect**: the list appears instantly (served from the permanent local cache — research.md R2 — no network round-trip visible).
7. Fresh-install the app (or clear app storage) while offline.
8. **Expect**: the list still renders, from the bundled local fallback asset (FR-017, SC-008), not a blank screen.

## Scenario 2 — Read a Surah (User Story 2, P2)

1. From the Surah tab, tap any Surah (e.g. Al-Baqarah).
2. **Expect**: navigates to the Surah Reading screen; ayat render continuously, each with a numbered badge, in the current saved font family/size.
3. Scroll through the whole Surah.
4. **Expect**: correct right-to-left layout, no visual breakage, generous line height.
5. Go offline, back out, and open a Surah never previously opened this session and not in the bundled fallback's cached range (if applicable) — or simulate by disabling network before any Surah content has ever been fetched.
6. **Expect**: an explicit unable-to-load state, not a blank reader (FR-018).

## Scenario 3 — Browse by Juz (User Story 3, P3)

1. On the Quran tab, switch to the Juz tab.
2. **Expect** (first time this session): a brief load (all 30 Juz endpoints fetched in parallel — research.md R3), then Juz headers 1–30 appear with the correct Surahs grouped beneath each.
3. Compare a Surah entry under a Juz header against its Surah-tab counterpart (e.g. Al-Baqarah).
4. **Expect**: identical fields (number, Arabic name, transliteration, meaning, revelation type, ayah count) — Juz view only changes grouping, not the underlying data (FR-004).
5. Find a Surah known to span two Juz (e.g. Al-Baqarah spans Juz 1–3).
6. **Expect**: it appears under each Juz section it has ayat in.
7. Switch back to the Surah tab, then back to Juz.
8. **Expect**: instant on every subsequent switch (cached — research.md R2/R3), no repeated network fetch.
9. Tap a Surah entry while on the Juz tab.
10. **Expect**: navigates to that Surah's Reading screen, identically to tapping it from the Surah tab.

## Scenario 4 — Search for a Surah by name (User Story 4, P4)

1. On the Quran tab, type a partial Arabic name or transliteration (e.g. "baq" or "بقرة") into the search field.
2. **Expect**: the view replaces itself with a flat list of only matching Surahs; the Surah/Juz tab switcher becomes unusable.
3. Type a query matching nothing (e.g. "zzz").
4. **Expect**: an explicit no-results state, not an empty blank list.
5. Clear the search field.
6. **Expect**: the view restores whichever tab (Surah or Juz) was active before the search began.
7. Type a Surah's English meaning only (e.g. "Opening", not "Fatiha"/"الفاتحة").
8. **Expect**: no match — search only checks Arabic name and transliteration, per spec.md's Clarifications.

## Scenario 5 — Adjust Quran font settings (User Story 5, P5)

1. From the Quran tab's app bar, tap the font-settings icon.
2. **Expect**: a bottom sheet opens with a font size control and 3 font family options, each with a live preview of sample Quran text.
3. Adjust the font size slider/stepper.
4. **Expect**: any currently visible Quran-styled text updates immediately, without closing the sheet.
5. Select a different font family.
6. **Expect**: same immediate effect.
7. Close the sheet, open a Surah's Reading screen.
8. **Expect**: it renders in the just-selected family/size.
9. Open the font-settings sheet again from the Reading screen's app bar instead, and change the size again.
10. **Expect**: the change applies immediately there too — same live `QuranFontSettingsCubit.instance`, not a separate copy.
11. Fully restart the app (guest or signed-in).
12. **Expect**: the previously selected font family and size are still applied (FR-015).
13. While signed in, change font settings on Device A; open the app on Device B (same account).
14. **Expect**: Device B shows Device A's font family/size (verify via `select quran_font_family, quran_font_size from user_preferences where user_id = ...` in the Supabase SQL editor).
15. As a guest, change font settings.
16. **Expect**: no `user_preferences` row is touched (persists locally only).

## Automated checks to run before calling this feature done

- `flutter analyze` — clean, no new lints.
- `flutter test test/features/quran/` — new unit tests for `QuranCubit`, `SurahReadingCubit`, `QuranFontSettingsCubit` (mirroring `test/features/prayers/`'s `bloc_test`/`mocktail` pattern) and `QuranRepositoryImpl`, covering: fetch-once-reuse-forever caching for all three content types, Juz grouping correctness (including a Surah spanning multiple Juz), search matching (Arabic name/transliteration only, not meaning), guest-never-syncs, and font-setting local+remote persistence.
- Manual side-by-side comparison against the design reference (spec.md SC-007) for: Surah tab, Juz tab, search/no-results state, Surah Reading screen, and the font-settings bottom sheet — **flagged as not verifiable during planning** (research.md R10); complete this manually against whatever design reference is available at implementation time.
