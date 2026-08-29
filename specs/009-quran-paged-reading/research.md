# Phase 0 Research: Quran Paged Reading

No `NEEDS CLARIFICATION` markers remain in the Technical Context. The items below record the investigation that resolved every open technical question.

## R1: Source of truth for page↔ayah mapping

**Decision**: Use both new/updated bundled assets, each for the direction it answers best:
- **Page → ayah range** (needed to assemble a `MushafPage`): `assets/quran/page_boundaries.json`, a 604-entry map of `pageNumber → {startSurah, startAyah, endSurah, endAyah}`. Already generated and validated (`assets/quran/validation_report.json`: `pages_indexed: 604`, `pages_expected: 604`, `ayat_with_no_page_assigned: []`, `ayat_seen_on_conflicting_pages: []`, `non_monotonic_page_jumps_within_surah: []`, `status: "PASS"`).
- **Ayah → page number** (needed to resolve "first page of surah N" / "first page of Juz J" without scanning all 604 boundary entries): the `page` field now present on every verse object in `assets/quran/chapters/{n}.json` (confirmed via diff — e.g. chapter 1's 7 ayahs all carry `"page": 1`).

**Rationale**: These two already-generated indices are complementary and exactly cover both query directions this feature needs, with zero additional data-processing code required at runtime — `getPage(pageNumber)` is a boundary lookup + two cheap `List<Ayah>.where(...)` filters over already-cached surah data; `firstPageOfSurah(n)` is `(await getSurah(n)).first.pageNumber`; `firstPageOfJuz(j)` is the same lookup applied to the Juz's `{startSurah, startAyah}` (from the existing `juz_boundaries.json`, already loaded by `getJuzSections()`).

**Alternatives considered**: Deriving page boundaries from ayah `page` fields alone at runtime (scan every cached surah, group by page). Rejected — `page_boundaries.json` already is that computation, done once and validated; redoing it on-device is pure duplicated, unvalidated work for no benefit.

## R2: Pages that span multiple surahs

**Decision**: 51 of the 604 pages have `startSurah != endSurah` (confirmed by scanning `page_boundaries.json` — e.g. page 106 ends Surah 4 at ayah 176 and continues into Surah 5 ayah 1–2). Of those, **7 pages near the end of the Quran span three surahs at once** — e.g. page 604 runs Al-Ikhlas (112) ayah 1 through An-Nas (114) ayah 6, passing entirely through Al-Falaq (113) in between (found while implementing — this correction supersedes the original 2-slot design). `MushafPage` therefore models a page as an ordered `List<MushafPageSurahRun>` (`{surah, ayahs}`), one run per surah the page contains, walking every surah number from `startSurah` to `endSurah` inclusive — not a fixed start/end pair. The reading UI renders each run's ayahs via the existing `AyahTextView`, with a `SurahTransitionDivider` (surah name + Bismillah, styled like the existing `_basmala` precedent in `quran_font_family_preview_card.dart`, using `AppTypography.ornamentalFontFamily` per its constitution-documented purpose) inserted before every run after the first.

**Rationale**: The run-list shape is unambiguous, requires no heuristic (e.g. "ayah number resets to 1" would also work but is an inferred signal; the explicit `startSurah`/`endSurah` fields from `page_boundaries.json` are already authoritative and require no inference), and — critically — generalizes to any number of surahs on a page instead of assuming at most two. It also directly answers "which surah name does the app bar show on a mixed page" (research.md R3) and "is this page a surah's first/last page" (needed for FR-007/FR-008's boundary-crossing continuity, which `PageView` already gives for free — see R4) without extra state.

**Alternatives considered**:
- A single flat `List<Ayah>` with a "surah changed" computed at render time by diffing consecutive ayahs' surah numbers. Rejected as an unnecessary inference layer over data that already states the split explicitly.
- A fixed `startSurah`/`endSurah` 2-slot shape (the original design). Rejected once the 7 three-surah pages were found — it would silently drop the middle surah's ayahs entirely, a real FR-002/FR-003 violation, not just an incomplete increment.

## R3: App-bar surah label on a mixed page

**Decision**: The app bar shows the **starting surah's** name/type/ayah-count (`page.startSurah`), unchanged for the whole page regardless of scroll position within an overflowing page.

**Rationale**: The page is a single static swipe-unit (not a scroll-linked view where "current surah" could dynamically update); showing the surah the reader lands on first when the page appears is the least surprising default, and matches how the imported design's own "SURAH BOUNDARY" example is framed (each page shown with one clear surah header). The `SurahTransitionDivider` inline in the page body (R2) already surfaces the second surah's name at the exact point it begins, so no information is lost.

**Alternatives considered**: Showing both surah names concatenated in the header on mixed pages. Rejected — spec.md doesn't require this, and it would need extra layout work in a header UI (`_SurahReadingTitle`) built for exactly one surah's info; the inline divider already communicates the transition.

## R4: Boundary crossing and over-swipe clamping (FR-007–FR-009)

**Decision**: A single `PageView.builder(itemCount: 604, physics: const ClampingScrollPhysics())`, one item per absolute Mushaf page (index `i` = page `i+1`), covering the *entire* Quran — not one `PageView` per surah. Surah-boundary crossing (FR-007/FR-008) and edge clamping at page 1/604 (FR-009) both fall out of this for free: swiping past a surah's last page simply lands on the next `PageView` item, which happens to be the next surah's first page (no special-case code); swiping past index 0 or 603 is a no-op because `PageView` never scrolls past its declared `itemCount` bounds. `ClampingScrollPhysics` (not the default iOS-style bouncing physics) avoids an overshoot/rubber-band animation at the true start/end that could visually suggest "there's more" when there isn't.

**Rationale**: This is the simplest possible design that satisfies every edge case in spec.md's Edge Cases and User Story 2 acceptance scenarios with zero custom index-arithmetic or "am I at a surah boundary" branching — the fixed 1–604 index space already *is* the seamless, surah-agnostic sequence the spec asks for.

**Alternatives considered**: A `PageView` scoped to the current surah's pages only, with custom logic to swap to a new `PageView` (and a new `SurahReadingCubit` load) when crossing a boundary. Rejected — meaningfully more code (transition detection, a second load-and-swap step, re-synchronizing `PageController`) to reproduce behavior `PageView`'s own bounded `itemCount` already provides, directly working against the "implemented safely... no big changes" instruction.

## R5: Cache compatibility with the updated bundled assets

**Decision**: Bump the per-surah ayah cache key from `AppPersistenceDataKeys.quranSurahCachePrefix` (`'quran_surah_cache'`) to a new value (e.g. `'quran_surah_cache_v2'`). The page-boundaries cache gets its own new key. No migration/deletion of the old keys — they're simply never read again (harmless orphaned Hive entries).

**Rationale**: `QuranRepositoryImpl` is "local-only, load-once-reuse-forever" (existing doc comment) — `getSurah(n)` returns straight from Hive if `_prefs.contains(cacheKey)`, without ever re-reading the bundled asset. Since the user has already updated `assets/quran/chapters/{n}.json` to add a `page` field per ayah, any device that already ran the app before this update has a cached surah **without** that field. Without a key bump, `getSurah(n)` would keep serving the stale, page-less cached copy forever post-update, silently breaking `firstPageOfSurah`/page rendering for exactly the users who'd already used the app — a correctness bug that would be easy to miss in a fresh-install test but would hit every upgrading user. A key bump is the minimal, additive fix: old cache orphaned, new cache built from the updated bundled asset on first read, no explicit invalidation/migration code needed anywhere.

**Alternatives considered**:
- Making `AyahModel.fromJson`'s `page` field nullable and having callers treat a `null` `pageNumber` as "re-fetch from asset." Rejected — this pushes a real runtime branch (staleness detection) into what should be a simple cached-read path, is easy to get subtly wrong (e.g. only checking the *first* ayah's page), and only protects this one field; a key bump protects against *any* shape drift in the cached JSON, present or future, with one line.
- Calling `SharedPrefHandler.instance!.removeAllOf(keys: [...])` for all 114 per-surah keys once, gated by a "migrated" flag. Rejected — more moving parts (a new persisted flag, a loop over 114 keys, a startup hook) for the same outcome the key bump achieves with zero new runtime code.

## R6: New icons

**Decision**: 4 new `assets/icons/*.svg` files + `AppIcons` keys, transcribed directly from the inline SVG markup already present in the imported design's "04 Surah Reading — Paged" section (same origin as the existing `share.svg`, which is byte-for-byte identical to this design's share icon — confirmed by direct comparison):

| AppIcons key | Used for | Source |
|---|---|---|
| `audioDownload` | App bar, "تنزيل صوت السورة" (download surah audio) — no-op this phase per spec Assumptions | Headphone-shape path, design's app-bar audio button |
| `pageJump` | App bar, "الانتقال إلى صفحة" (open jump sheet) | Open-book path, design's app-bar page-jump button |
| `listen` | Reading-actions bar, "استماع" — no-op this phase | Circle + play-triangle, design's bottom-bar listen button |
| `tafseer` | Reading-actions bar, "تفسير" — no-op this phase | Open-book-pages path, design's bottom-bar tafseer button |

`share` (bottom bar) and `close` (jump sheet's dismiss button) reuse the already-existing `AppIcons.share`/`AppIcons.close` — no new asset needed for either. `bookmark`/`bookmarkFilled` exist but are deliberately **not** used in the reading-actions bar this phase (spec Assumptions: 3 buttons only, no bookmark).

**Rationale**: Matches Constitution Principle IV exactly (every icon key added to `AppIcons` before use, asset sourced from the project's own imported design rather than invented) and the project's established pattern of transcribing this design's inline SVGs 1:1 (`share.svg` precedent).

## R7: Jump control transition style

**Decision**: `PageController.jumpToPage(target - 1)` (instant, no animation) for both page-number and Juz jumps.

**Rationale**: Spec.md's Alternate Flow B says only "System navigates directly to that page" — no transition style is mandated. An instant jump avoids animating through up to 603 intermediate pages' worth of visual motion for a long-distance jump (e.g. page 1 → page 600), which `animateToPage` would otherwise do at a fixed velocity, producing a jarring multi-second flip-through for large jumps. Adjacent-page swiping (the common case) is unaffected — that's `PageView`'s own gesture-driven scroll, not this jump path.

**Alternatives considered**: `animateToPage` with a fixed short duration regardless of distance. Rejected — a fixed duration either flies unreadably fast for long jumps or crawls for short ones; distance-proportional duration is unnecessary complexity for a control whose entire purpose (per User Story 3) is to skip swiping.

## R8: Reading-actions bar scope

**Decision**: A new `QuranReadingActionsBar` widget with exactly 3 buttons — listen (`AppIcons.listen`), tafseer (`AppIcons.tafseer`), share (`AppIcons.share`) — each wired to an empty/no-op `onTap`, per the feature description's explicit instruction. No bookmark button is rendered at all (not present-but-disabled — simply absent), matching "just (3 buttons)" literally.

**Rationale**: Directly follows the user's Implement-section instruction; keeping the omitted bookmark button out entirely (rather than a visible-but-disabled placeholder) avoids implying functionality that doesn't exist yet and avoids extra dead code (a disabled-state style) for a button not being shipped this phase.
