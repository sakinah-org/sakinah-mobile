# Research: Quran Screen

Phase 0 output. Each decision resolves a gap between spec.md's requirements and what already exists in the codebase (per the Explore survey of `lib/features/home/`, `lib/features/prayers/`, `lib/shared/bloc/`, `lib/utils/style/app_typography.dart`, the live Supabase schema, and `pubspec.yaml`).

## R1. Remote data endpoints

**Decision**: Add three sibling static methods on `AppEndPoints` alongside the existing `quranCloudBaseUrl`/`quranCloudAyah(...)`:

```dart
static String quranCloudSurahList() => "$quranCloudBaseUrl/surah";
static String quranCloudJuz(int juzNumber) => "$quranCloudBaseUrl/juz/$juzNumber/quran-uthmani";
static String quranCloudSurah(int surahNumber) => "$quranCloudBaseUrl/surah/$surahNumber/quran-uthmani";
```

Called via `DioClient.instance.request(RequestInstructions(url: ..., method: 'GET'))`, exactly like `AyahRepositoryImpl.getAyahOfToday()` already does — same base host, same client, no auth.

**Rationale**: Matches the existing single precedent for this API family exactly; no new network abstraction needed.

## R2. Repository shape and caching strategy

**Decision**: One `QuranRepository` (`getSurahList()`, `getJuz(int)`, `getSurah(int)` — matching the exact method names given in the feature brief's Logic section) backed by `QuranRepositoryImpl`. Unlike `AyahRepositoryImpl`'s *daily* cache (content changes every day) or `PrayerTimesRepositoryImpl`'s *same-day-and-location* cache, Quran text and metadata never change — so caching here is **fetch-once, reuse-forever**: check Hive first; if present, return it with no network call at all; only fetch remotely on a genuine cache miss (first run, or a previous fetch never succeeded). A successful fetch is cached permanently; there is no "staleness" concept to invalidate against, unlike the day-boundary logic in the two existing repositories.

**Rationale**: Reusing the existing day/location-based cache pattern verbatim would be wrong here — it would silently force a full 114-Surah refetch (or 30-Juz refetch) on every "new day," for data that is permanently static. A simpler "have it locally? use it. Otherwise fetch and store" rule is both correct for this domain and less code than the two existing patterns.

## R3. Juz view data

**Decision**: `getJuz(int)` calls `GET /juz/{n}/quran-uthmani` and groups the returned `ayahs[]` by `surah.number` to build that Juz's surah headers, exactly as specified in the feature brief's Logic section. Because the Juz tab (FR-003/004) must show all 30 Juz sections at once (not one Juz loaded at a time), the repository fetches all 30 Juz endpoints in parallel (`Future.wait`) the first time the Juz tab is opened, then caches the combined per-Juz surah-grouping result locally (R2's fetch-once rule applies per Juz number too) — so every subsequent visit to the Juz tab across the app's lifetime is served from cache with zero network calls.

**Rationale**: The feature brief explicitly specifies this endpoint and grouping approach (not a lighter-weight alternative like a static Juz-boundary table), so this plan follows it as given rather than substituting a different design. The one accepted tradeoff: each `/juz/{n}/quran-uthmani` response includes full ayah text (not just header metadata), so the first Juz-tab visit fetches more data than is strictly displayed (only surah headers are shown, not ayah bodies) — acceptable because it happens once, is parallelized, and is never repeated.

**Alternatives considered**: A bundled static Juz-boundary table (Juz→surah/ayah-range mapping, since Juz boundaries are fixed and never change) combined with the already-fetched Surah List — rejected as a plan-level substitution because the brief explicitly names the `/juz/{n}` endpoint and its grouping approach as the intended integration; not something to unilaterally replace.

## R4. Bundled local fallback content — flagged as a content-sourcing dependency, not a design decision

**Decision**: FR-017 requires all three fetches to fall back to "a bundled local copy of the Quran text/metadata" when the remote source is unavailable. This plan does **not** fabricate that dataset — Quran text is religious scripture and must come from a verified, authoritative source (the same Uthmani text AlQuran Cloud's own API is built from, e.g. Tanzil.net's published text corpus), not be approximated or generated. This is recorded here as an explicit **implementation-time task**: source a verified Uthmani-script Quran dataset (surah metadata + full ayah text, with enough structure to serve `getSurahList()`/`getJuz()`/`getSurah()` shapes offline) and bundle it as a local JSON asset (e.g. `assets/quran/quran_uthmani.json`), registered in `pubspec.yaml`'s `assets:` list. `/speckit-tasks` should carry this as its own explicit, verifiable task rather than bundling it silently inside a generic "implement repository" task.

**Rationale**: Getting scripture text wrong is a correctness/trust issue far more serious than a typical data bug; this must be sourced deliberately (with a named, checkable source) rather than guessed at during planning or implementation.

## R5. Font settings — state ownership and scope

**Decision**: A third Cubit, `QuranFontSettingsCubit`, singleton-scoped within the Quran feature (`lib/features/quran/presentation/bloc/quran_font_settings_cubit.dart`, `.instance` pattern matching `PrayerTimesCubit`/`SessionCubit`/`SettingsCubit`), separate from the two screen-level Cubits (R6). It owns `{fontFamily, fontSize}`, is provided once (at `MainPage`/`MyApp` level, not re-created per screen) so both the Quran tab and the Surah Reading screen read the *same* live instance, and the font-settings bottom sheet (opened from either screen's app bar) mutates it directly.

**Rationale**: Font selection is genuinely cross-screen state within one feature (both the Quran tab, per FR-012, and the Surah Reading screen need to read and instantly react to it) — a plain per-page-scoped Cubit re-created on each `BlocProvider` would lose the "apply immediately" requirement (FR-014) if the user opens the sheet from the list, backs out, and opens a Surah; a fresh instance would have to re-read Hive every time instead of already holding the current value. This mirrors the constitution's own singleton criterion ("cross-app state exposed at the widget-tree root") — here scoped to cross-*screen-within-feature* rather than cross-*app*, so it's declared inside `lib/features/quran/` rather than promoted to `lib/shared/`, since nothing outside this feature needs to read it.

**Alternatives considered**: Folding font state into `QuranCubit` (the list/tabs/search Cubit) — rejected because the Surah Reading screen would then need to depend on the browsing screen's Cubit for unrelated state, and the two Cubits the brief explicitly asked for (one per screen) would end up entangled.

## R6. Two page-level Cubits, per the feature brief's explicit instruction

**Decision**: `QuranCubit` (feature-scoped via `BlocProvider` at `QuranPage`) owns the Surah list, current tab (Surah/Juz), and search query/results — one Cubit handling the search interaction too, not a separate Bloc with discrete search events, matching Constitution Principle II's "Cubit for state driven by simple commands/data flow" and the brief's explicit "create Cubit class despite [i.e. including] the searching event." `SurahReadingCubit` (feature-scoped via `BlocProvider` at `SurahReadingPage`) owns a single Surah's loaded ayat for the reading screen. Both are plain Cubits, not global singletons — each has exactly one screen-level consumer, same reasoning as `PrayerNotificationSettingsCubit` in the Prayers feature.

**Rationale**: Directly matches the brief's explicit request ("for the Quran screen create Cubit class... for the Reading Surah screen use Cubit also") and Constitution Principle II.

## R7. Search implementation

**Decision**: `QuranCubit.search(String query)` filters the already-loaded `List<Surah>` in memory (Arabic name or transliteration, case-insensitive substring match per spec.md FR-006/Clarifications) and emits a filtered view; `clearSearch()` restores whichever tab (Surah/Juz) was active. No repository/network involvement at all, per spec.md FR-007.

**Rationale**: Directly satisfies FR-005–008; keeps search entirely inside `QuranCubit`, consistent with R6.

## R8. Font settings sync — reuse the existing `user_preferences` table

**Decision**: `public.user_preferences` (verified live via Supabase schema query) already has `quran_font_family` (text) and `quran_font_size` (integer, default `20`) columns, one row per `user_id` (unique constraint). `QuranRepositoryImpl` (or a small dedicated sync method on it) upserts `{user_id, quran_font_family, quran_font_size}` via `Supabase.instance.client.from('user_preferences').upsert(..., onConflict: 'user_id')` directly — mirroring `PrayerNotificationSettingsRepositoryImpl`'s direct-client-call precedent — gated on `SessionCubit.instance.currentUser?.id != null`, fire-and-forget, swallowing failures the same way. Add `AppEndPoints.userPreferencesTable = 'user_preferences'` as a new constant (no constant for this table exists yet — only `prayerNotificationSettingsTable` does).

**Rationale**: No new table/migration needed — this is exactly the "existing per-user preferences store" the spec's Assumptions section anticipated. Reusing an existing single-row-per-user table is simpler than the Prayers feature's five-row last-write-wins reconciliation: `user_preferences` only ever needs a last-write-wins compare on the two Quran columns specifically (not a per-item collection), so no `reconcileWithRemote`-style merge loop is needed — just "pull on load if authenticated, push on change."

## R9. The third font file — RESOLVED, no sourcing needed

**Decision**: ~~One more font family is still needed~~ **Superseded**: all three required Quran-appropriate font families already exist in `pubspec.yaml` as of the design-import pass below — `Lateef` (pre-existing default, `AppTypography.quranFontFamily`), `Amiri` (added since spec.md was written, `assets/fonts/amiri/`), and `KFGQPC Nastaleeq` (pre-existing, `assets/fonts/nastaleeq/w400.ttf`, registered as font family `Nastaleeq`). The design file (`Sakinah Screens.dc.html`, §05 "Font bottom sheet") confirms these are exactly the intended three: "three font families — each card renders the Basmala live in that face (**Lateef · Amiri Uthmani · KFGQPC Nastaleeq**)," labeled in the mockup as "Lateef · Naskh (default)," "Amiri · Uthmani," and "KFGQPC Nastaleeq · Ornamental." No new font file needs to be sourced — `T042` in tasks.md is repurposed from a content-sourcing task into a verification task.

**Correction to a prior assumption**: `lib/utils/style/app_typography.dart`'s doc comment currently states Nastaleeq is "ornamental... do not use for body or UI text," which this feature's font-settings selector deliberately does — the design explicitly wants it as a selectable Quran-reading option, not excluded from body text. This existing doc comment should be updated during implementation to note the Quran-reading-selector exception, rather than silently contradicted.

**Rationale**: Confirmed directly from the design source of truth (see R10) rather than inferred from the current `AppTypography` comment, which predates this feature and was written for a different purpose (preventing Nastaleeq from being used as a general UI/body font, not anticipating a font-choice feature that intentionally offers it for Quran reading).

**Post-implementation update**: during implementation, `assets/fonts/nastaleeq/w400.ttf` was removed from the repo and `pubspec.yaml` was updated to register a different set of dedicated Quran typefaces instead (`Kitab`, `MeQuran`, `QPCHafs`, alongside the already-present `Amiri`) — `Nastaleeq` is no longer a registered font family at all. `QuranFontSetting.availableFontFamilies` was updated to `Lateef`/`Amiri`/`QPCHafs` (QPCHafs — the standard King Fahd Complex "Hafs" Uthmani typeface — filling the design's "Uthmani" font slot in place of Nastaleeq). `AppTypography.ornamentalFontFamily` (Nastaleeq) reverts to its original ornamental-only role, unused by this feature; its doc comment was updated accordingly. `Kitab` and `MeQuran` are bundled but not currently used by any of the 3 selectable slots — available for a future adjustment.

## R10. Design fidelity (FR-019/SC-007) — RESOLVED, design imported this session

**Decision**: ~~No design-import tooling is reachable~~ **Superseded**: the `DesignSync` tool (matching the "claude_design MCP" described in the original brief) is available and was used to pull the actual design directly — project `b8146c64-eac6-43d8-bb96-45b29414f5e1` ("Sakinah Quran App UI"), file `Sakinah Screens.dc.html`, plus the linked `Sakinah Design System` project (`ddbd8c42-224a-4771-a973-322972f24505`) for tokens. Concrete findings now on record for implementation:

- **§03 "Quran — Surah & Juz tabs"**: app bar title "القرآن الكريم", search field placeholder "ابحث عن سورة…", tab labels "السور" (Surah) / "الأجزاء" (Juz), font-settings trigger is a plain **text button reading "Aa"** (not an SVG icon) top-right of the app bar — `AppIcons.fontSettings` (research.md R13) is unnecessary; a styled text button matches the design exactly. Surah row: diamond+square number badge, Arabic name (16px/700), "transliteration · meaning" (11px, secondary), revelation type + ayah count right-aligned (10.5px). Juz header: pill badge with the Juz number + Arabic label + ayah range.
- **§04 "Surah Reading"**: sticky mini-header (back chevron, Surah name + "مكية · ٧ آيات"-style Meccan/Medinan+ayah-count caption, "Aa" button), Basmala rendered in the ornamental font (30px) above the ayat, ayat in `--font-quran` (Lateef by default, 27px/56px line-height — close to but not identical to `AppTypography.quranLight/Dark`'s existing 26px/52px; reconcile the exact value against the live token at implementation time), each ayah closed by a circular numbered badge (26px). The mockup also shows a bottom toolbar with Listen/Bookmark/Share actions — **out of scope for this feature** per spec.md's Assumptions (no audio, no bookmarking, no sharing in v1); do not implement these from the design alone, they belong to a later feature.
- **§05 "Font bottom sheet"**: titled "إعدادات القراءة" (Reading Settings), a size row ("حجم الخط" / font size, "28 pt" shown as an example current value) with decrement/increment buttons + a slider, then "نوع الخط" (font type) with the three font cards described in R9 — selected state is a colored border + filled brand-color checkmark circle, unselected is a plain border + empty circle. Sheet slides up over a dimmed/blurred scrim of the reading screen behind it.
- **Design tokens** (`tokens/colors.css`, `tokens/typography.css`, `tokens/fonts.css`, `tokens/spacing.css`, fetched from the `ddbd8c42` project): `--font-ui: Tajawal`, `--font-quran: Lateef`, `--font-display-ornamental: KFGQPC Nastaleeq` — matching `AppTypography`'s existing `uiFontFamily`/`quranFontFamily`/`ornamentalFontFamily` exactly (no new tokens needed). Color/spacing tokens (`--brand-primary: #158467` / dark `#87D1A4`, `--bg`/`--surface`/`--text-primary` etc., `--space-*`, `--radius-*`) likewise line up with what `AppColors` already defines, consistent with this design system having already been imported for the `001`/`002` features.

**Rationale**: The tool and design content were actually reachable this session (unlike the prior planning pass, which correctly reported them as unreachable at the time) — recorded here in full rather than re-summarized, so `/speckit-implement` has concrete, quotable reference points instead of needing to re-import the design from scratch.

## R11. Screen wiring

**Decision**: Replace the `Container()` placeholder at index 1 of `MainPage`'s `PageView` (`lib/features/main/ui/pages/main_page.dart`) with `const QuranPage()` — no new named route needed for the tab itself, matching how `HomePage` at index 0 is wired directly, not via `Navigator`. The Surah Reading screen, reached by a push (not a tab), gets a new named route `AppRoutes.surahReading`, added to `generateRoute()`'s switch, with the tapped Surah's number passed via `RouteSettings.arguments` — matching the existing `AppRoutes.prayers` precedent and the constitution's "no named-route argument passing beyond `RouteSettings.arguments`" rule.

**Rationale**: Matches the two existing navigation patterns already in the codebase (tab = direct `PageView` child; pushed screen = named route) exactly, introducing no third pattern.

## R12. Bottom nav "Quran" label

**Decision**: While wiring the Quran tab, also fix `MainBottomNavigationBar`'s hardcoded `"Quran"` label to use `TranslationKeys`/`translator.word(...)` (adding the one missing key), since this feature directly touches that tab. The sibling `"Home"`/`"Settings"` labels are left as-is — out of scope, not directly touched by this feature.

**Rationale**: Constitution's compliance-review guidance: fix a directly-touched pre-existing inconsistency in the same change rather than silently working around it; don't expand scope to unrelated labels this feature doesn't touch.

## R13. New icon assets — RESOLVED, no new SVG needed

**Decision**: ~~A new `AppIcons` key and matching SVG asset are needed for the font-settings control~~ **Superseded by R10**: the design (`Sakinah Screens.dc.html` §03/§04) renders the font-settings app-bar control as a plain styled text button reading "Aa" (a `Container`/`OutlinedButton`-equivalent with two stacked-size letters), not an SVG glyph. No new icon asset is needed for it. The existing `search` icon key/asset (`AppIcons.search` → `assets/icons/search.svg`) is still reused as-is for the search field, unaffected by this correction.

**Rationale**: Matches the design source of truth rather than assuming an icon was required by default — avoids fabricating SVG artwork that the actual design never called for.
