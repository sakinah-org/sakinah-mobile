# Quickstart: Quran Paged Reading Validation

Manual end-to-end checks, one per user story from `spec.md`. Runs fully offline on simulator/emulator — no physical-device-only dependency.

## Prerequisites

- `assets/quran/page_boundaries.json` added to `pubspec.yaml`'s `assets:` list, then `flutter pub get` / restart the app so the new asset is bundled.
- Fresh install (or clear app storage) for at least one pass, to exercise the cache-key-bump path (research.md R5) with no pre-existing stale cache.
- For the "existing install" regression check below, a build from *before* this feature (or a manually pre-seeded old-shape Hive cache) is needed — otherwise skip that one check.

## US1 — Read a Surah page by page

1. From the Surah list, tap any Surah (e.g. Al-Baqarah). **Expect**: Surah Reading screen opens directly on that surah's first Mushaf page — page-number badge visible (spec.md FR-004), text in the user's currently saved font family/size.
2. Swipe right-to-left. **Expect**: next sequential page, badge increments by 1, content is a different, correct ayah range.
3. Swipe left-to-right. **Expect**: back to the previous page, badge decrements by 1.
4. Note the page number for a specific piece of content (e.g. "page containing Al-Baqarah ayah 30"), navigate away and back to the same content. **Expect**: identical page number both times (SC-005).

## US2 — Cross surah boundaries seamlessly

1. Jump to the last page of a surah that is not the 114th (e.g. via the jump sheet — see US3 below — to the surah's last page; or swipe there from its first page). Swipe right-to-left once more. **Expect**: the very next page shown is the first page of the following surah, page-number badge continues sequentially, no interstitial screen, header surah label updates to the new surah's name.
2. From that new surah's first page, swipe left-to-right. **Expect**: back onto the previous surah's last page.
3. Navigate to page 604 (the last page of the Quran) and swipe right-to-left. **Expect**: nothing happens — still on page 604 (FR-009).
4. Navigate to page 1 and swipe left-to-right. **Expect**: nothing happens — still on page 1 (FR-009).
5. Navigate to one of the 51 mixed pages (research.md R2 — e.g. page 106) without swiping past it (jump directly via the jump sheet). **Expect**: the page renders Surah 4's last ayahs (176), then a visible surah-transition divider (Bismillah + "Al-Ma'idah"), then Surah 5's ayahs 1–2, all within the *same* page — swiping right-to-left from here goes to page 107, not a new "half-page."

## US3 — Jump to a page or Juz

1. From the Surah Reading screen, open the jump control (the new book/page icon in the app bar). **Expect**: a bottom sheet with two tabs — Page Number and Juz.
2. On the Page Number tab, enter a valid page number (e.g. 250) and submit. **Expect**: sheet closes, screen is now on page 250 exactly.
3. Reopen the sheet, switch to the Juz tab, select a Juz (e.g. Juz 5). **Expect**: sheet closes, screen navigates to Juz 5's first page.
4. Reopen the sheet, Page Number tab, attempt to enter/submit a value outside 1–604 (e.g. 605, or 0). **Expect**: submission is prevented/rejected — no navigation occurs, no crash.

## US4 — Font overflow keeps the page scrollable

1. Open the font settings sheet (existing "Aa" app-bar button, unchanged) and set the largest available font size.
2. Navigate to a page with a relatively high ayah/word density. **Expect**: the page's text visibly exceeds the screen; the page becomes vertically scrollable (drag up/down) and every word is reachable by scrolling — nothing is clipped or unreachable.
3. Compare that page's ayah content against the same page number at the default font size (reset font size, navigate back to the same page number via the jump sheet). **Expect**: identical set of ayahs — only the rendering changed, not the page boundary (SC-004).
4. Navigate to a page with low ayah/word density at a normal font size. **Expect**: no vertical scroll offered/needed.

## App bar & reading-actions bar (per the Implement instructions)

1. Confirm the app bar shows 3 trailing controls: an audio-download icon, the page-jump/book icon, and the existing "Aa" font button.
2. Tap the audio-download icon. **Expect**: no crash, no visible effect (explicitly a no-op this phase).
3. Confirm a 3-button reading-actions bar is present at the bottom of the Surah Reading screen: Listen, Tafseer, Share — and that **no bookmark button** is present anywhere on this bar.
4. Tap each of the 3 buttons in turn. **Expect**: no crash, no visible effect (all no-op this phase).

## Regression check — pre-existing cache (research.md R5)

Only if a pre-update install/cache is available:

1. On a device/emulator with an app build from before this feature already installed and already having opened at least one Surah (populating the old-shape per-surah cache), install this update over it (or otherwise seed the old Hive key `quran_surah_cache_<n>` with pre-update-shaped data) and open that same Surah.
2. **Expect**: Surah Reading screen still opens successfully on the correct first page (no null-pageNumber crash, no stuck loading state) — confirming the cache-key bump routed around the stale entry rather than trying to use it.

## Verification references

- Contracts: [contracts/quran_repository_paging_contract.md](./contracts/quran_repository_paging_contract.md), [contracts/surah_reading_cubit_contract.md](./contracts/surah_reading_cubit_contract.md).
- Data model: [data-model.md](./data-model.md) — `MushafPage`, `Ayah.pageNumber`, `SurahReadingState`.
- Automated coverage: unit tests for `QuranRepositoryImpl.getPage`/`firstPageOfSurah`/`firstPageOfJuz` (including at least one of the 51 mixed pages) and `bloc_test` coverage for `SurahReadingCubit.initialize`/`resolveJuzFirstPage` (see plan.md Testing).
