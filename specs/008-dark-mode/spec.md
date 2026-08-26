# Feature Specification: Dark Mode

**Feature Branch**: `008-dark-mode`

**Created**: 2026-08-26

**Status**: Draft

**Input**: User description: "The app should support a dark mode theme; the user switches between light and dark from a toggle button on the Settings screen. Theme state is managed by the existing SettingsCubit and the selected theme is cached in Shared Preferences so it persists across restarts. Dark theme colors follow the project's design system Color & Theme Board."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Switch Between Light and Dark Theme (Priority: P1)

A user on the Settings screen taps a theme toggle and the entire app immediately switches between light and dark appearance, without navigating away or restarting the app.

**Why this priority**: This is the core value of the feature — without a working toggle, dark mode does not exist from the user's perspective. Every other behavior (persistence, visual correctness) only matters once the toggle works.

**Independent Test**: Open Settings, tap the theme toggle, and confirm every visible screen (current and any screen navigated to afterward) immediately renders in the newly selected theme.

**Acceptance Scenarios**:

1. **Given** the app is in light mode, **When** the user taps the theme toggle on Settings, **Then** the app switches to dark mode immediately, with no restart and no navigation required.
2. **Given** the app is in dark mode, **When** the user taps the theme toggle on Settings, **Then** the app switches back to light mode immediately.
3. **Given** the theme toggle is visible on the Settings screen, **When** the user views it, **Then** it clearly indicates which mode (light or dark) is currently active.

---

### User Story 2 - Theme Choice Persists Across Sessions (Priority: P1)

A user who selects dark mode, then closes and reopens the app, finds the app still in dark mode without needing to toggle again.

**Why this priority**: A theme preference that resets on every launch is a broken experience and would make the toggle feel non-functional; persistence is what makes the choice a true "setting" rather than a session-only visual state.

**Independent Test**: Toggle to dark mode, fully close the app, relaunch it, and confirm it opens directly in dark mode (and equivalently for light mode).

**Acceptance Scenarios**:

1. **Given** the user has selected dark mode, **When** they close and relaunch the app, **Then** the app opens in dark mode.
2. **Given** the user has selected light mode, **When** they close and relaunch the app, **Then** the app opens in light mode.
3. **Given** the user has never changed the theme, **When** they open the app for the first time, **Then** the app opens in the default theme (light mode).

---

### User Story 3 - Every Screen Renders Correctly in Dark Mode (Priority: P2)

A user browsing the app in dark mode sees every screen — not just Settings — rendered with dark-appropriate colors: backgrounds, text, icons, cards, and brand accents all remain legible and visually consistent with the app's design system.

**Why this priority**: The toggle and persistence (P1) make dark mode switchable and stick, but the feature only delivers real value if the whole app looks correct in dark mode. This is a broader, app-wide validation on top of the switching mechanism.

**Independent Test**: With dark mode active, navigate through the app's main screens (Home, Prayer Times, Quran, Settings, and any modals/bottom sheets) and confirm text stays readable and no light-mode-only colors leak through.

**Acceptance Scenarios**:

1. **Given** dark mode is active, **When** the user visits any main screen of the app, **Then** backgrounds, surfaces, text, icons, and interactive elements use the app's dark theme colors with sufficient contrast to remain readable.
2. **Given** dark mode is active, **When** the user opens a bottom sheet or dialog (e.g., language selector, logout confirmation), **Then** it also renders using dark theme colors.

---

### Edge Cases

- What happens if the cached theme preference is missing or unreadable (e.g., first install, cleared storage)? The app MUST fall back to the default light theme rather than crashing or showing a mixed/undefined theme.
- What happens if the user rapidly taps the toggle multiple times? Each tap MUST resolve to a stable, correct final state (the last selection wins) with no flicker between unrelated theme states.
- What happens if the user changes the theme while a modal, bottom sheet, or dialog is open? The open surface MUST update to the new theme immediately, consistent with the rest of the app.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Settings screen MUST display a toggle control that lets the user switch the app's theme between light mode and dark mode.
- **FR-002**: The theme toggle MUST visibly reflect the currently active theme at all times (including immediately after app launch and immediately after being toggled).
- **FR-003**: Selecting a theme via the toggle MUST apply the change to the entire app immediately, without requiring an app restart or screen navigation.
- **FR-004**: The system MUST persist the user's selected theme so that it is retained across app restarts.
- **FR-005**: On app launch, the system MUST read the persisted theme preference (if any) and apply it before the first screen is shown to the user.
- **FR-006**: When no theme preference has been persisted yet (e.g., first launch), the system MUST default to light mode.
- **FR-007**: All screens, modals, bottom sheets, and dialogs in the app MUST render using the active theme's colors — light theme colors in light mode, dark theme colors in dark mode.
- **FR-008**: Dark mode's colors (backgrounds, surfaces, text, borders, brand/accent colors) MUST follow the values defined in the project's design system for the dark theme, so dark mode is visually consistent with the rest of the app rather than an ad-hoc palette.
- **FR-009**: Theme state management and the toggle behavior MUST be handled through the app's existing settings state controller, consistent with how other settings (such as language) are managed, rather than introducing a separate/parallel mechanism.

### Key Entities

- **Theme Preference**: The user's selected app appearance (light or dark), including which value is currently applied and whether it has been explicitly set by the user or is still at its default.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can switch the app's entire appearance between light and dark mode in a single tap, with the change visible in under 1 second.
- **SC-002**: 100% of app restarts after a theme selection open the app in the previously selected theme.
- **SC-003**: Across the app's main screens and common overlays (modals, bottom sheets, dialogs), zero screens show light-mode-only colors while dark mode is active.
- **SC-004**: A first-time user who has never touched the toggle always sees the app open in light mode.

## Assumptions

- The visual toggle control itself (e.g., switch vs. segmented control) follows the existing Settings options-list styling already used for the other settings rows; this feature does not introduce a new interaction pattern.
- "Dark mode" is a binary, user-selected choice (light or dark) for this feature — following the system/OS appearance setting automatically is out of scope unless added as a future enhancement.
- The app's light and dark color palettes (including the dark theme's specific color values) are defined by the project's existing design system and are applied as-is; this feature does not invent new colors.
- Persisting the theme preference uses the same local on-device storage mechanism already used for the existing language preference, keeping both settings consistent in how they survive app restarts.
- The feature applies to the entire app (all screens/features), not a subset, since theming is a global, cross-cutting concern.
