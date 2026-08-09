# Feature Specification: Home Page (Prayer Times & Ayah of Today)

**Feature Branch**: `002-home-page`

**Created**: 2026-08-09

**Status**: Draft

**Input**: User description: "Build Home Page: create Home Page and show it as the first screen in the main screen. Home page shows two main components (Prayer Times, Ayah of Today). Prayer Times shows the remaining time to the next prayer and the day's prayer times in short form. Ayah of Today shows a single randomly-selected ayah each day; the ayah text can be long so the layout must stay responsive. Small details shown at the top of the page: current day name and the Hijri date. Prayer times must be usable without a live connection by falling back to the most recently retrieved times, and must clearly communicate when no times can be shown at all rather than fabricating them. The Ayah of Today must show today's verse when available, fall back to the most recently cached verse (labeled as cached) when offline, and offer a manual retry when no verse can be shown at all. Users can jump from the Home prayer summary to the full Prayers screen to adjust settings. UI must pixel-match the provided Sakinah design system Home screen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See today's prayer times and the next prayer at a glance (Priority: P1)

A user opens the app and, without any extra navigation, immediately sees the five daily prayer times for their location and which prayer is coming up next, with a live countdown to it.

**Why this priority**: This is the single most frequent reason someone opens a prayer-focused app — checking "what time is the next prayer." It is the primary daily-use driver and must work standalone as the app's landing experience.

**Independent Test**: Can be fully tested by opening the Home tab with a configured location and confirming all five prayer times are displayed correctly and the next upcoming prayer is visually distinguished with a live-updating countdown, independent of the Ayah of Today component being built.

**Acceptance Scenarios**:

1. **Given** a user has a location configured (detected or manually set) and opens the Home tab, **When** the screen loads, **Then** the system displays all five prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) for that location and today's date.
2. **Given** the Home tab is open and displaying prayer times, **When** the current time is between two prayers, **Then** the next upcoming prayer is visually emphasized and a countdown shows the remaining time until it begins.
3. **Given** the Home tab is open with an active countdown to the next prayer, **When** the countdown reaches zero (the prayer time arrives), **Then** the emphasis and countdown automatically move to the following prayer without requiring the user to refresh or reopen the screen.
4. **Given** a user has no location configured yet, **When** they open the Home tab, **Then** the system shows a clear message directing them to set a location, without fabricating prayer times.
5. **Given** prayer times were previously loaded successfully and the device later goes offline, **When** the user opens the Home tab, **Then** the system shows the most recently retrieved prayer times so the user is not left with no information.
6. **Given** the device is offline and no prayer times have ever been successfully retrieved, **When** the user opens the Home tab, **Then** the system shows an explicit "unable to load prayer times" state rather than blank or fabricated times.

---

### User Story 2 - Read a new reflection verse each day (Priority: P2)

A user opens the Home tab and sees a single verse of the Quran (Ayah of Today), in Arabic with its translation, that changes once per day so returning users see something fresh.

**Why this priority**: This is a secondary daily-engagement driver — valuable and central to the app's purpose, but the app remains functional as a prayer-times tool without it, and it depends on the same "first thing you see on Home" placement as Story 1.

**Independent Test**: Can be fully tested by opening the Home tab on a given day and confirming a single ayah with its translation is displayed, then reopening the app later the same day and confirming the same ayah is shown (not a new random one), independent of the Prayer Times component being built.

**Acceptance Scenarios**:

1. **Given** a user opens the Home tab for the first time on a given day and the device is online, **When** the ayah has not yet been retrieved today, **Then** the system fetches a random ayah, displays it in Arabic with its translation, and remembers it for the rest of that day.
2. **Given** a user has already seen today's ayah, **When** they reopen the Home tab again the same day, **Then** the system shows the same ayah without a new network request.
3. **Given** the ayah of the day is longer than fits comfortably on screen, **When** it is displayed, **Then** the surrounding layout adjusts so the full verse remains readable without cutting off text or breaking the rest of the Home layout.
4. **Given** a new day has started and the device is online, **When** the user opens the Home tab, **Then** the system fetches and displays a new random ayah for the new day.
5. **Given** the device is offline and a network request for today's ayah fails, **When** a verse from a previous day is available locally, **Then** the system displays that previously-seen verse along with a subtle indicator that it is not today's verse.
6. **Given** the device is offline, a network request fails, and no verse has ever been retrieved or stored locally, **When** the user opens the Home tab, **Then** the system shows a message that the ayah is unavailable due to connectivity along with a manual retry action.
7. **Given** the "unavailable" state is shown after a failed retrieval, **When** the user taps retry after connectivity is restored, **Then** the system attempts to fetch and display the ayah again.

---

### User Story 3 - Jump from Home to prayer settings (Priority: P3)

A user viewing the prayer times summary on Home wants to adjust their prayer configuration (e.g., location, calculation method) and can reach that screen directly from Home instead of hunting through navigation.

**Why this priority**: This is a convenience/navigation shortcut layered on top of Story 1 — useful, but Home already delivers its core value without it, and the destination screen (full Prayers settings) is assumed to exist independently of this feature.

**Independent Test**: Can be fully tested by tapping the edit affordance on the Home prayer times summary and confirming the user is taken to the full Prayers screen, independent of the Ayah of Today component.

**Acceptance Scenarios**:

1. **Given** a user is viewing the prayer times summary on Home, **When** they tap the edit/settings affordance on that summary, **Then** the system navigates them to the full Prayers screen.

---

### Edge Cases

- What happens when the user's device date/time or timezone changes while the app is open (e.g., timezone travel)? The countdown and "current day" label should reflect the corrected local time on next recalculation rather than silently drifting.
- What happens if all five prayers for the day have already passed (after Isha, before midnight)? The system indicates the next prayer is Fajr of the following day rather than showing no next prayer or an error.
- What happens if the device's calendar cannot produce a Hijri date (unsupported locale/platform quirk)? The Gregorian day name still displays; the Hijri date element degrades gracefully rather than breaking the header.
- What happens if the ayah translation or Arabic text is unusually short (e.g., a very brief ayah)? The layout should not look broken or leave excessive awkward empty space.
- What happens if the user switches their configured location while Home is open? The prayer times and next-prayer countdown update to reflect the new location without requiring app restart.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST present the Home page as the first/default screen the user sees within the app's main navigation.
- **FR-002**: The system MUST display the current day name and the current Hijri date at the top of the Home page.
- **FR-003**: The system MUST display all five daily prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) for the user's configured location, in a condensed/summary form, on the Home page.
- **FR-004**: The system MUST identify which of the five prayers is next relative to the current time and visually distinguish it from the others.
- **FR-005**: The system MUST display a live-updating countdown to the next prayer's start time, and MUST automatically advance to the following prayer once the countdown elapses, without requiring the user to reload the page.
- **FR-006**: The system MUST provide a way for the user to navigate from the Home prayer times summary to the full Prayers screen (e.g., via an edit affordance).
- **FR-007**: When prayer times cannot be freshly retrieved (e.g., no connectivity), the system MUST fall back to the most recently successfully retrieved prayer times, if any exist.
- **FR-008**: When no prayer times are available at all (no fresh data and no fallback), the system MUST display an explicit "unable to load" state rather than blank, zeroed, or fabricated times.
- **FR-009**: When no location is configured for the user, the system MUST display explicit guidance to configure a location rather than attempting to show prayer times.
- **FR-010**: The system MUST display a single "Ayah of Today" on the Home page, consisting of the verse text in Arabic and its translation.
- **FR-011**: The system MUST select the Ayah of Today at random and MUST keep the same ayah displayed for the remainder of the calendar day for a given user, regardless of how many times the Home page is reopened that day.
- **FR-012**: The system MUST select a new random Ayah of Today at the start of each new calendar day (on next retrieval opportunity) when the device is online.
- **FR-013**: When a fresh Ayah of Today cannot be retrieved (e.g., no connectivity) but a previously retrieved ayah exists locally, the system MUST display that previously retrieved ayah along with a visible indicator that it is not necessarily today's verse.
- **FR-014**: When no Ayah of Today can be retrieved and none exists locally, the system MUST display a message indicating the ayah is unavailable due to connectivity, along with a manual action allowing the user to retry.
- **FR-015**: The Home page layout MUST remain fully readable and visually intact regardless of the length of the day's ayah text, including unusually long or unusually short verses.
- **FR-016**: The Home page MUST be usable by both guest and authenticated users; the Ayah of Today and Prayer Times components MUST NOT require the user to be signed in.
- **FR-017**: The system MUST re-evaluate and refresh the displayed prayer times whenever the user's configured location or calculation preference changes, without requiring an app restart.
- **FR-018**: The Home page's visual presentation (layout, spacing, iconography, and styling of the day/date header, prayer times summary, and Ayah of Today card) MUST match the provided Sakinah design system reference for the Home screen.

### Key Entities

- **Prayer Times (for a day)**: The set of five named prayer start times (Fajr, Dhuhr, Asr, Maghrib, Isha) applicable to a specific date and a specific location, along with an indicator of which one is currently "next."
- **Ayah of Today**: A single Quranic verse consisting of Arabic text, a translation, and its source reference (surah and verse position), associated with the calendar date on which it was selected for display, with an indicator of whether it reflects today or a prior day.
- **Location/Prayer Preference**: The user's configured location and calculation preference used to determine prayer times; owned outside this feature but consumed by it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can determine the time remaining until the next prayer within 2 seconds of opening the app, without any additional taps.
- **SC-002**: The next-prayer countdown and emphasis update automatically within 5 seconds of the previous prayer's start time passing, with no user action required.
- **SC-003**: 100% of Home page visits show either live prayer times, clearly-labeled fallback prayer times, or an explicit "unable to load" message — never a blank or silently incorrect prayer schedule.
- **SC-004**: 100% of Home page visits show either today's ayah, a clearly-labeled non-today cached ayah, or an explicit "unavailable, retry" message — never a blank ayah section.
- **SC-005**: A user reopening the app multiple times within the same day sees the same Ayah of Today each time, confirmed across at least 3 reopens in manual testing.
- **SC-006**: The Home page remains fully readable (no clipped text, no overlapping elements) for ayah lengths ranging from a very short verse to one of the longest verses in the Quran.
- **SC-007**: A user can reach the full Prayers settings screen from Home in a single tap.
- **SC-008**: The implemented Home screen is visually indistinguishable from the provided design reference when compared side-by-side (spacing, color, type, iconography).

## Assumptions

- A location (detected or manually configured) and a calculation-method preference are already collectible/settable elsewhere in the app (e.g., an existing or parallel Prayers/Settings feature); this feature consumes that configuration rather than defining how it is set.
- "Today" and "next day" boundaries are based on the device's local date and time.
- The Home page is reached via the app's main bottom navigation and is the default/first tab shown on launch, per the existing 3-tab main navigation (home, quran, settings).
- Prayer time calculation source and Ayah source are external services outside this feature's control; this spec describes required user-facing behavior (fresh data, fallback, and unavailable states) without prescribing the specific service or caching mechanism.
- Both guest and authenticated users see the same Home page content; no personalization differences between the two are in scope for this feature.
- The full "Prayers" settings screen referenced by the edit affordance (Story 3) is an existing or separately-specified screen; this feature only defines the entry point to it, not its contents.
- Visual/pixel-parity with the design reference is treated as a hard acceptance bar (SC-008) since it was explicitly required, evaluated by manual side-by-side comparison rather than automated visual regression tooling.
