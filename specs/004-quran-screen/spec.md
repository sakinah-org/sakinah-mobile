# Feature Specification: Quran Screen

**Feature Branch**: `004-quran-screen`

**Created**: 2026-08-10

**Status**: Draft

**Input**: User description: "Feature: Quran — one of the three main screens of the app. The Quran screen shows a list of Surahs in order (number, Arabic name, transliteration & meaning, revelation type, ayah count). The screen has two tabs (Surah, Juz); the Juz tab regroups the same list under inline Juz dividers. The app bar carries a font-settings button (top-right, opens a bottom sheet). The top of the screen shows a search field for finding a Surah by name; while searching, the view changes to a filtered list of matching Surahs. A separate Surah Reading screen is reached by tapping a Surah from the Quran screen. Use Cases: (UC-01) Read the Quran — user opens the Quran tab, sees the Surah list (default, sorted 1-114), taps a Surah, is taken to the Surah Reading screen which renders the ayat in the user's saved font family/size; browsing by Juz shows the same content grouped under Juz headers 1-30; no reading progress is persisted in v1. (UC-02) Adjust font settings — from the Quran tab or the Surah Reading screen, the user taps the font/settings icon, gets a bottom sheet with a font size control and a font family selector showing 3 live previews, changes apply immediately, are written to SharedPreferences, and additionally to Supabase's user_preferences if authenticated, persisting across restarts and (if authenticated) across devices. Logic: content is sourced from the Al Quran Cloud API (base https://api.alquran.cloud/v1, no auth) — GET /surah for the Surah list (fields: number, name, englishName, numberOfAyahs), GET /juz/{juzNumber}/quran-uthmani for Juz grouping (group ayahs[] by surah.number to build each Juz section's surah headers, keeping Juz content identical to the Surah tab's data), GET /surah/{number}/quran-uthmani for Surah reading (ayahs[].text rendered continuously, ayahs[].numberInSurah as the badge number). Fonts are local only: 3 bundled .ttf fonts switched via fontFamily, with family/size read from and written to SharedPreferences directly. Repository methods are one-shot fetches (getSurahList, getJuz(int), getSurah(int)), no polling; on failure for any of the three, fall back to a bundled local Quran asset. Selected font is cached in SharedPreferences and, if authenticated, also stored in Supabase. Searching a Surah by name is internal only (no API calls). UI: follow and pixel-match the Sakinah design system reference (Sakinah Screens design file) for the Surah/Juz tabs section."

## Clarifications

### Session 2026-08-10

- Q: Should typing a Surah's English meaning (e.g., "Opening") also match it in search, or only its Arabic name and transliteration? → A: Search matches only the Arabic name and transliteration; the English meaning is not a search field.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse all Surahs in order (Priority: P1)

A user opens the Quran tab and sees the Surah tab (the default view): all 114 Surahs listed in canonical order, each showing its number, Arabic name, transliteration, meaning, revelation type, and ayah count.

**Why this priority**: This is the entry point for every other Quran-related interaction in the app and is valuable on its own — a user can already identify and locate any Surah without any other part of this feature existing yet.

**Independent Test**: Can be fully tested by opening the Quran tab and confirming all 114 Surahs appear, correctly ordered and labeled, with smooth scrolling — independent of search, Juz grouping, reading, or font settings.

**Acceptance Scenarios**:

1. **Given** the user opens the app and taps the Quran tab, **When** the screen loads, **Then** the Surah tab is shown by default with all 114 Surahs listed in order 1–114.
2. **Given** the Surah list is displayed, **When** the user inspects any entry, **Then** it shows that Surah's number, Arabic name, transliteration, meaning, revelation type, and ayah count.
3. **Given** the Surah list is displayed, **When** the user scrolls through it, **Then** the list scrolls smoothly with no missing or duplicated entries.
4. **Given** the device has no network connection, **When** the user opens the Quran tab for the first time with no previously cached data, **Then** the system falls back to the bundled local Quran data so the list still renders.

---

### User Story 2 - Read a Surah (Priority: P2)

A user taps a Surah from the list and is taken to a dedicated Surah Reading screen where that Surah's ayat render continuously, each numbered, in the user's currently saved font family and size.

**Why this priority**: This delivers the feature's core value — actually reading the Quran. It depends on User Story 1 for its normal entry point, but is independently testable by opening the reading screen for any given Surah directly.

**Independent Test**: Can be fully tested by opening any Surah's reading screen and confirming its ayat render with correct numbering and in the currently configured font — independent of the Juz tab, search, or changing font settings mid-session.

**Acceptance Scenarios**:

1. **Given** the user is on the Surah tab, Juz tab, or a search results list, **When** the user taps a Surah entry, **Then** the system navigates to the Surah Reading screen for that Surah.
2. **Given** the Surah Reading screen is open, **When** the ayat render, **Then** the text flows continuously (not as isolated short lines) with each ayah's number shown in a badge.
3. **Given** the user has a saved font family and size, **When** the Surah Reading screen renders, **Then** the ayat use that saved font family and size.
4. **Given** the user scrolls through a long Surah, **When** reading, **Then** the layout renders correctly right-to-left with generous line height and no visual breakage.
5. **Given** the requested Surah's text cannot be loaded (offline and not previously cached or bundled), **When** the reading screen opens, **Then** the system shows an explicit unable-to-load state rather than a blank or broken screen.

---

### User Story 3 - Browse the Quran by Juz (Priority: P3)

A user switches from the Surah tab to the Juz tab and sees the same Surah data regrouped under inline Juz headers (1–30), enabling a structured, sequential reading plan.

**Why this priority**: This is an alternate way to browse the same underlying data already delivered by User Story 1 — valuable for users following a Juz-based reading plan, but not required for the feature's core browse-and-read value to exist.

**Independent Test**: Can be fully tested by switching to the Juz tab and confirming all 30 Juz headers appear with the correct Surahs grouped beneath them, matching the Surah tab's underlying data — independent of search or reading.

**Acceptance Scenarios**:

1. **Given** the user is on the Quran tab, **When** the user switches to the Juz tab, **Then** the system displays Juz headers 1–30 with the relevant Surah entries grouped beneath each one.
2. **Given** the Juz tab is displayed, **When** the user inspects a Surah entry under a Juz header, **Then** it shows the same information (number, Arabic name, transliteration, meaning, revelation type, ayah count) as its counterpart on the Surah tab.
3. **Given** a Surah spans more than one Juz, **When** the user browses the Juz tab, **Then** that Surah appears under every Juz section it has ayat in.
4. **Given** the user taps a Surah entry while on the Juz tab, **When** the tap registers, **Then** the system navigates to that Surah's Reading screen, identically to tapping it from the Surah tab.

---

### User Story 4 - Search for a Surah by name (Priority: P4)

A user types into the search field at the top of the Quran tab and sees the list replaced with only the Surahs matching that name.

**Why this priority**: A convenience shortcut on top of User Story 1's already-complete list — valuable for quickly finding a specific Surah, but not required for the feature's baseline browsing/reading value.

**Independent Test**: Can be fully tested by typing a partial Surah name (in Arabic or transliterated form) and confirming only matching Surahs are shown, and that clearing the search restores the previous view — independent of which tab was active or of reading/font settings.

**Acceptance Scenarios**:

1. **Given** the user is on the Quran tab, **When** the user types into the search field, **Then** the list view is replaced with a filtered list containing only Surahs whose Arabic name or transliteration matches the query.
2. **Given** a search query is active, **When** the query matches no Surah, **Then** the system shows an explicit no-results state rather than an empty blank list.
3. **Given** a search query is active, **When** the user clears the search field, **Then** the system restores whichever tab (Surah or Juz) was active before the search began.
4. **Given** a search query is active, **When** the user views the screen, **Then** the Surah/Juz tab switcher is not usable until the search is cleared.

---

### User Story 5 - Adjust Quran font settings (Priority: P5)

From either the Quran tab or the Surah Reading screen, a user taps the font-settings icon in the app bar, adjusts the font size and/or picks one of 3 font families (each shown with a live preview), and sees the change apply immediately and persist.

**Why this priority**: This is a comfort/personalization layer on top of User Story 2's reading experience — valuable for readability, but the feature is usable in its default font without it.

**Independent Test**: Can be fully tested by opening the font-settings bottom sheet, changing the size and family, confirming the change applies instantly, and confirming it's still applied after an app restart — independent of which Surah is open or how the user navigated there.

**Acceptance Scenarios**:

1. **Given** the user is on the Quran tab or the Surah Reading screen, **When** the user taps the font-settings icon in the app bar, **Then** a bottom sheet opens showing a font size control and a font family selector with 3 live previews.
2. **Given** the bottom sheet is open, **When** the user adjusts the font size or selects a different font family, **Then** the change is reflected immediately on any currently rendered Quran text.
3. **Given** the user has changed their font settings, **When** the app is fully restarted, **Then** the previously selected font family and size are still applied.
4. **Given** the user is authenticated and changes their font settings, **When** the user signs in on a second device, **Then** the same font family and size are applied there.
5. **Given** the user is a guest (not authenticated) and changes their font settings, **When** the change is saved, **Then** it persists locally on that device only.

---

### Edge Cases

- What happens if the search query matches no Surah? The system shows an explicit "no results" state instead of an empty blank list.
- What happens if a user opens a Surah's Reading screen while offline and that Surah was never cached or bundled locally? The system shows an explicit unable-to-load state instead of a blank reader.
- What happens if a Surah spans multiple Juz? It appears under every Juz section it has ayat in, consistent with how the underlying Quran data groups individual ayat by Surah.
- What happens to the Surah/Juz tab switcher while a search is active? It becomes unusable; clearing the search restores whichever tab was active before searching began.
- What happens the very first time a user opens the Quran tab, before any font setting has ever been chosen? A default font family and size are applied automatically, with no action required from the user.
- What happens if an authenticated user changes their font settings on two devices while one was offline? The most recently changed value (by timestamp) wins once the offline device reconnects, consistent with how this app already reconciles other per-user settings.
- What happens if both the remote Quran data source and the bundled local fallback fail for a given screen? The system shows an explicit unable-to-load state for that screen rather than a blank or crashed one.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST display a list of all 114 Surahs, sorted by their canonical order (1–114), as the default view when the Quran tab is opened.
- **FR-002**: Each Surah entry in the list MUST show its number, Arabic name, transliteration, meaning, revelation type (Meccan/Medinan), and ayah count.
- **FR-003**: The system MUST provide two view modes on the Quran tab: a "Surah" view (flat, numerically ordered) and a "Juz" view (the same Surah data grouped under Juz section headers 1–30).
- **FR-004**: When the Juz view is shown, the system MUST group Surah entries under their corresponding Juz header(s); a Surah spanning multiple Juz MUST appear under every Juz section it has ayat in.
- **FR-005**: The system MUST provide a search field at the top of the Quran tab that filters the Surah list as the user types.
- **FR-006**: Search MUST match a Surah if the query is found within its Arabic name or its transliteration, case-insensitively, without requiring an exact or prefix match; the Surah's English meaning MUST NOT be searched.
- **FR-007**: Search MUST be performed entirely against already-loaded local data; it MUST NOT trigger any additional network request.
- **FR-008**: While a search query is active, the system MUST replace the current view with a flat list of only the matching Surahs; clearing the search MUST restore whichever tab (Surah or Juz) was active immediately before the search began.
- **FR-009**: Tapping a Surah entry, from the Surah view, the Juz view, or a search results list, MUST navigate the user to a dedicated Surah Reading screen for that Surah.
- **FR-010**: The Surah Reading screen MUST render that Surah's ayat continuously, with each ayah's number shown in a distinct badge/marker.
- **FR-011**: The Surah Reading screen MUST render Quran text using the user's currently saved font family and font size.
- **FR-012**: The app bar on both the Quran tab and the Surah Reading screen MUST include a font-settings control that opens a bottom sheet.
- **FR-013**: The font-settings bottom sheet MUST let the user adjust font size and MUST let the user choose among 3 available Quran font families, each shown with a live preview of sample Quran text rendered in that font.
- **FR-014**: Changing the font size or font family in the bottom sheet MUST apply immediately to any currently rendered Quran text, without requiring the sheet to be closed first.
- **FR-015**: The system MUST persist the selected font family and size locally on the device, for both guest and authenticated users, so the selection is restored after an app restart.
- **FR-016**: When the user is authenticated, the system MUST additionally persist the selected font family and size to the user's account, so the same selection is applied when they use the app on another device signed into that account.
- **FR-017**: The system MUST load Surah list, Juz, and Surah Reading content from a remote Quran data source, and MUST fall back to a bundled local copy of the Quran text/metadata if that remote source is unavailable for a given request.
- **FR-018**: When neither the remote source nor the bundled local fallback can provide the content for a given view, the system MUST show the user an explicit unable-to-load state rather than an empty or broken screen.
- **FR-019**: The Quran tab (both view modes), the search experience, the Surah Reading screen, and the font-settings bottom sheet MUST visually match the provided Sakinah design system reference.

### Key Entities

- **Surah**: A chapter of the Quran; identified by its number (1–114), with an Arabic name, a transliteration, an English meaning, a revelation type (Meccan or Medinan), and its total ayah count. The Surah list is this entity in aggregate, ordered by number.
- **Juz**: One of the 30 traditional reading-division sections of the Quran, numbered 1–30; used only to regroup Surah entries for the Juz view — this feature does not include a separate Juz-level reading screen.
- **Ayah**: A single verse within a Surah; identified by its number within that Surah, with its Arabic text; rendered on the Surah Reading screen.
- **Quran Font Setting**: The user's chosen font family (one of 3 available) and font size for rendering Quran text; always stored on the device, and additionally against the user's account when authenticated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can locate a specific Surah by name via search in under 5 seconds from the moment they start typing.
- **SC-002**: The 114-entry Surah list scrolls with no visible stutter or dropped frames, matching the scroll quality of the app's other list-based screens.
- **SC-003**: Opening a Surah's Reading screen shows readable Quran text within 2 seconds under normal network conditions, and immediately when the content was previously cached or falls back to bundled local data.
- **SC-004**: All 114 Surahs are viewable in both the Surah view and the Juz view, with no Surah missing (beyond the expected repetition of Surahs that span multiple Juz).
- **SC-005**: A font size or font family change is visibly applied within 1 second of selection, and is confirmed still applied after a full app restart across at least 3 manual restart cycles.
- **SC-006**: An authenticated user who changes their Quran font settings on one device sees the same settings automatically applied the next time they open the app on a second device signed into the same account.
- **SC-007**: The Quran tab, Surah Reading screen, and font-settings bottom sheet achieve full visual parity with the provided Sakinah design system reference, confirmed by side-by-side comparison.
- **SC-008**: If the remote Quran data source is unreachable, users can still browse the Surah list and read at least the bundled fallback content, with no crash or blank screen, across 100% of manual offline test passes.

## Assumptions

- The remote Quran data source is the same external Quran content service already used elsewhere in the app for Quran content (the Home screen's "Ayah of Today").
- A Surah's "meaning" (its English-translated title) and "revelation type" are available from that same data source alongside the fields already used elsewhere in the app.
- Search matches a Surah by either its Arabic name or its transliteration, case-insensitively, as a substring match, performed entirely on already-loaded local data rather than via any additional network request.
- Of the 3 selectable Quran font families this feature requires, only one Quran-appropriate font is currently bundled in the app; two additional font files will need to be sourced and added as part of building this feature.
- Font settings sync (for authenticated users) targets the app's existing per-user preferences store rather than introducing a new one, consistent with how this app already centralizes per-user settings.
- Visual parity with the referenced Sakinah design system is verified against a live design import at implementation-planning time, following the same approach already used for this app's Home and Authentication screens; this specification states the fidelity requirement without embedding exact design tokens itself.
- This version of the feature does not include reading-progress tracking, bookmarking, audio recitation, translation/tafsir display, or a verse-by-verse (as opposed to continuous) rendering mode — these are out of scope.
- A Surah's displayed metadata (name, transliteration, meaning, revelation type, ayah count) is identical whether it's shown on the Surah view or under a Juz header — the Juz view only changes grouping, not the underlying per-Surah facts shown.
