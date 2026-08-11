# Feature Specification: Quran Fonts & Local Data Source Update

**Feature Branch**: `005-quran-fonts-local-source`

**Created**: 2026-08-11

**Status**: Draft

**Input**: User description: "Update Feature \"Quran\" — increase the Quran fonts from 3 to 4 and change the font set itself to Amiri, Kitab, Me Quran, and QPC Hafs; also change the data source used for local/offline reading by importing local sources from the quran-json repository, split as one local file per Surah (for performance) plus one local list file covering both the Surah view and the Juz view, instead of a single combined local source. No changes required to the domain or presentation layers; no critical UI changes beyond the extra font option."

## Clarifications

### Session 2026-08-11

- Q: Should the Quran tab, Juz tab, and Surah Reading screen keep fetching from the remote Quran content service as their primary source (with the new local files only used as an offline fallback, as today), or should the new bundled local files become the sole source for this content, with the remote service no longer used at all? → A: The new bundled local files become the sole source; the Quran screen (Surah list, Juz grouping, Surah Reading) no longer depends on any remote/network content service.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the Quran with no network dependency (Priority: P1)

A user opens the Quran tab, browses the Surah list or Juz list, and opens any Surah to read it — all of this works identically whether or not the device has a network connection, because the Surah list, Juz grouping, and every Surah's text are now bundled on the device rather than fetched from a remote service.

**Why this priority**: This is the core of the update — it removes the feature's only remaining dependency on network availability and an external content service, making Quran reading fully reliable regardless of connectivity.

**Independent Test**: Can be fully tested by disabling network connectivity entirely (airplane mode) and confirming the Surah tab, Juz tab, search, and every Surah's Reading screen all load and render correctly, with no loading delay or unable-to-load state caused by connectivity.

**Acceptance Scenarios**:

1. **Given** the device has no network connection at all, **When** the user opens the Quran tab, **Then** all 114 Surahs load and display exactly as they would with a network connection.
2. **Given** the device has no network connection, **When** the user switches to the Juz tab, **Then** all 30 Juz sections and their grouped Surahs load and display exactly as they would with a network connection.
3. **Given** the device has no network connection, **When** the user opens any Surah's Reading screen, **Then** that Surah's ayat render correctly and without any perceptible loading delay.
4. **Given** the user opens a Surah's Reading screen, **When** the screen loads, **Then** only that Surah's own data is loaded, not the data for all 114 Surahs.
5. **Given** a Surah's on-device data is somehow missing or unreadable, **When** the user opens that Surah's Reading screen, **Then** the system shows an explicit unable-to-load state rather than a blank or broken screen.

---

### User Story 2 - Choose from 4 Quran fonts (Priority: P2)

A user opens the font-settings bottom sheet (from the Quran tab or the Surah Reading screen) and now sees 4 selectable Quran font families, each with a live preview, instead of the previous 3.

**Why this priority**: This is a personalization improvement layered on top of the existing reading experience — valuable for readability and choice, but not required for the feature's baseline browse-and-read value.

**Independent Test**: Can be fully tested by opening the font-settings bottom sheet and confirming exactly 4 font family options are shown, each with a distinct live preview, and that selecting each one visibly changes the rendered Quran text to that family.

**Acceptance Scenarios**:

1. **Given** the user opens the font-settings bottom sheet, **When** the font family selector renders, **Then** it shows exactly 4 options — Amiri, Kitab, Me Quran, and QPC Hafs — each with its own live preview of sample Quran text.
2. **Given** the user selects any of the 4 font families, **When** the selection is made, **Then** any currently rendered Quran text updates immediately to that family.
3. **Given** the user selects a font family and restarts the app, **When** the Quran tab or Surah Reading screen next renders, **Then** the previously selected font family (one of the 4) is still applied.
4. **Given** a user had previously selected a font family that is no longer offered after this update, **When** their settings are next loaded, **Then** the system automatically applies the new default font family in its place, with no error or broken state shown to the user.

---

### Edge Cases

- What happens if a Surah's bundled on-device data file is missing or fails to parse? The system shows an explicit unable-to-load state for that Surah's Reading screen rather than a blank or crashed one.
- What happens to a user's previously saved font family selection if it no longer exists in the new 4-family set? The system automatically substitutes the new default font family the next time settings are loaded, without prompting the user or showing an error.
- What happens to the combined Surah/Juz list if it fails to load on-device? The system shows an explicit unable-to-load state for the Quran tab rather than an empty or broken screen (this should not occur in practice since the list ships with the app, but the system must still handle it defensively).
- What happens during search while offline? No change — search already operates entirely against already-loaded local data with no network calls.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST offer exactly 4 selectable Quran font families — Amiri, Kitab, Me Quran, and QPC Hafs — replacing the previous set of 3 families.
- **FR-002**: The font-settings bottom sheet MUST show a live preview of sample Quran text for each of the 4 font families.
- **FR-003**: The system MUST source the Surah list (used by both the Surah view and the Juz view, including each Surah's number, Arabic name, transliteration, meaning, revelation type, ayah count, and Juz grouping) from data bundled with the app, without making any network request.
- **FR-004**: The system MUST source each Surah's ayah text from its own separate on-device data, containing only that Surah's content, so that opening one Surah does not require loading data for any other Surah.
- **FR-005**: The Quran tab (Surah view and Juz view), the search experience, and the Surah Reading screen MUST NOT depend on any remote/network content service; all Surah list, Juz grouping, and ayah text data MUST come from data bundled with the app.
- **FR-006**: If a user's previously saved font family selection is no longer part of the current 4-family set, the system MUST automatically apply the new default font family the next time that user's settings are loaded, without showing an error.
- **FR-007**: If a specific Surah's on-device data cannot be read, the system MUST show an explicit unable-to-load state for that Surah's Reading screen rather than a blank or broken screen.
- **FR-008**: All other existing Quran tab behavior — browsing order, search matching rules, Juz grouping display, continuous ayah rendering with numbered badges, and font size/family persistence (local always, plus account-level sync when authenticated) — MUST remain unchanged by this update.
- **FR-009**: The Quran tab, Surah Reading screen, and font-settings bottom sheet MUST continue to visually match the existing Sakinah design system reference, with the only visible change being the fourth font option in the font-settings bottom sheet.

### Key Entities

- **Surah**: Unchanged from the existing feature — a chapter of the Quran identified by its number (1–114), with an Arabic name, a transliteration, an English meaning, a revelation type (Meccan or Medinan), and its total ayah count.
- **Juz**: Unchanged — one of the 30 traditional reading-division sections of the Quran, used to regroup Surah entries for the Juz view.
- **Ayah**: Unchanged — a single verse within a Surah, identified by its number within that Surah, with its Arabic text.
- **Quran Font Setting**: The user's chosen font family and font size for rendering Quran text; the selectable font family is now one of 4 (Amiri, Kitab, Me Quran, QPC Hafs), still stored on the device always and additionally against the user's account when authenticated.
- **Bundled Quran Dataset**: The on-device Quran content shipped with the app, made up of one combined list file (covering all 114 Surahs' metadata and Juz groupings, for both the Surah view and Juz view) and 114 separate per-Surah files (each containing one Surah's ayah text) — replacing the previous single combined local source and no-longer-used remote service.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can browse the Surah list, browse the Juz list, and open any Surah's Reading screen with full content displayed within 1 second, regardless of network connectivity.
- **SC-002**: 100% of manual test passes with network connectivity fully disabled show identical Surah list, Juz list, search, and Surah Reading behavior compared to the same passes with connectivity enabled.
- **SC-003**: Opening a Surah's Reading screen only loads that Surah's own data, keeping per-Surah load times consistent regardless of Surah length, rather than degrading as more Surahs are read in a session.
- **SC-004**: The font-settings bottom sheet shows exactly 4 font family options with 4 working live previews, confirmed by visual inspection.
- **SC-005**: A user who had a now-removed font family selected before this update sees a valid, correctly rendered font family automatically applied after the update, with zero manual action required and no error shown.
- **SC-006**: All 114 Surahs remain viewable in both the Surah view and the Juz view after the data source change, with no Surah missing or duplicated beyond the expected repetition of Surahs spanning multiple Juz.

## Assumptions

- The new default Quran font family (used for users who have never chosen one, and for users being migrated off a removed family) is QPC Hafs, the standard Uthmani typeface, replacing the previous default; the exact default can be adjusted at implementation time without changing this specification's intent.
- "Me Quran" (one of the 4 font families) refers to the same typeface already informally called "MeQuran" elsewhere in this app's existing font handling.
- The combined Surah/Juz list file and the 114 per-Surah files together contain all fields the existing feature already displays (Arabic name, transliteration, meaning, revelation type, ayah count, Juz grouping, ayah text) — no field currently shown to users is dropped by this data source change.
- Because the bundled local dataset now fully covers Surah list, Juz grouping, and Surah reading content, the "remote source with local fallback" behavior described in the original Quran feature is retired for this content; this does not affect other features (e.g., the Home screen's "Ayah of Today") that may separately use a remote Quran content service.
- This update does not change reading progress tracking, bookmarking, audio recitation, translation/tafsir display, or the continuous (non verse-by-verse) rendering mode — these remain out of scope, consistent with the original feature.
- No data migration is required for a user's saved font size, since font size selection is unaffected by this update; only the font family value may need to fall back to the new default if it no longer matches one of the 4 available families.
