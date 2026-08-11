# Feature Specification: Settings Screen

**Feature Branch**: `006-settings-screen`

**Created**: 2026-08-11

**Status**: Draft

**Input**: User description: "Build Settings screen with an account section (guest vs. authenticated views), a settings options list (Prayer Times, Qibla Compass, Change Language, Logout), a language-selection bottom sheet (Arabic/English only), and a Qibla Compass screen with live heading, low-accuracy calibration prompt, and a static-bearing fallback when no magnetometer is present."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See My Account Status at a Glance (Priority: P1)

Whether signed in or browsing as a guest, a user opening Settings immediately understands their account state: a guest sees an explanation that signing in will save their data to an account, and a signed-in user sees their name and email.

**Why this priority**: This is the first thing every user sees on this screen, on every visit, and it is the anchor for the rest of the feature (login prompt for guests, personalization for authenticated users). Without it, Settings has no identity context at all.

**Independent Test**: Open Settings as a guest and confirm the guest prompt appears; sign in, reopen Settings, and confirm the same section now shows the account's name and email. Fully testable without any of the other user stories being built.

**Acceptance Scenarios**:

1. **Given** the user is browsing as a guest, **When** they open Settings, **Then** the account section shows a guest message explaining that signing in will save their data to an account, with a way to start sign-in.
2. **Given** the user is signed in, **When** they open Settings, **Then** the account section shows their name and email instead of the guest message.
3. **Given** the user is a guest and completes sign-in from Settings, **When** they return to the Settings screen, **Then** the account section updates to show their name and email without needing to leave and reopen the screen a second time.

---

### User Story 2 - Reach Prayer Times, Qibla Compass, and Language Settings from One Place (Priority: P1)

A user opens Settings and finds a single list of options to jump to Prayer Times, open the Qibla Compass, or change the app language — regardless of whether they are a guest or signed in.

**Why this priority**: This is the core navigational purpose of the Settings screen — a hub to the app's other configuration and utility screens. It delivers value independent of account state and independent of the deeper Qibla/language implementations being complete.

**Independent Test**: From Settings, tap each option and confirm it opens the correct screen (Prayer Times screen, Qibla Compass screen, language bottom sheet). Testable as soon as the options list and navigation targets exist, even with placeholder destination screens.

**Acceptance Scenarios**:

1. **Given** the user is on the Settings screen, **When** they tap "Prayer Times," **Then** the app navigates to the Prayer Times screen.
2. **Given** the user is on the Settings screen, **When** they tap "Qibla Compass," **Then** the app opens the Qibla Compass screen.
3. **Given** the user is on the Settings screen, **When** they tap "Change Language," **Then** the language bottom sheet opens.
4. **Given** the user is a guest, **When** they view the options list, **Then** no "Logout" option is shown.
5. **Given** the user is signed in, **When** they view the options list, **Then** a "Logout" option is shown at the end of the list.

---

### User Story 3 - Switch the App Language (Priority: P2)

A user opens the language bottom sheet from Settings, picks Arabic or English, and the entire app immediately reflects the new language and reading direction.

**Why this priority**: Language is a standalone, high-visibility preference that affects the whole app, but it is a self-contained slice on top of the options list from User Story 2.

**Independent Test**: Open the language bottom sheet, select the language that isn't currently active, and confirm the app's text and layout direction (RTL for Arabic, LTR for English) update immediately and persist after closing and reopening the app.

**Acceptance Scenarios**:

1. **Given** the language bottom sheet is open, **When** the user selects a language, **Then** the sheet closes and the app's text and layout direction update immediately without a restart.
2. **Given** the app language was changed to Arabic, **When** the app is relaunched later, **Then** it opens in Arabic with right-to-left layout.
3. **Given** the language bottom sheet is open, **When** the user views it, **Then** the currently active language (Arabic or English) is visibly marked as selected.
4. **Given** the user selects the language that is already active, **When** the selection is confirmed, **Then** the sheet closes with no visible change.

---

### User Story 4 - Find the Qibla Direction (Priority: P2)

A user opens the Qibla Compass from Settings and sees a live compass that points toward the Kaaba as they turn, so they can orient themselves for prayer.

**Why this priority**: A clearly valuable, self-contained feature that works for guests and signed-in users alike, independent of the account section or language switching.

**Independent Test**: Open the Qibla Compass on a device with a working magnetometer and location access, and confirm the indicator rotates to track the Qibla bearing as the device is turned.

**Acceptance Scenarios**:

1. **Given** the device has a working magnetometer and location access, **When** the user opens Qibla Compass, **Then** the system computes the bearing to the Kaaba from the user's coordinates and shows a live compass that rotates as the device turns.
2. **Given** the compass sensor is reporting low accuracy, **When** the user is on the Qibla Compass screen, **Then** a calibration prompt (figure-eight motion) is shown until accuracy improves.
3. **Given** the device has no magnetometer, **When** the user opens Qibla Compass, **Then** the screen shows the Qibla bearing as a static degree value along with an explanatory message instead of a live compass.
4. **Given** location access is unavailable, **When** the user opens Qibla Compass, **Then** the screen explains that location is required and offers a way to grant it, without crashing or showing a blank screen.

---

### User Story 5 - Log Out Without Losing Local Functionality (Priority: P3)

A signed-in user taps Logout, confirms, and the app returns to guest mode while keeping locally stored preferences (like language) intact and the app fully usable.

**Why this priority**: Only relevant to already-signed-in users and depends on User Stories 1 and 2 existing first (account section + options list), but it completes the account lifecycle covered by this feature.

**Independent Test**: While signed in, tap Logout, confirm the action, and verify the session ends, the account section reverts to the guest view, and previously set local preferences (e.g., language) are unchanged.

**Acceptance Scenarios**:

1. **Given** the user is signed in, **When** they tap "Logout," **Then** a confirmation prompt appears before anything happens.
2. **Given** the confirmation prompt is shown, **When** the user confirms, **Then** the session ends, the account section reverts to the guest view, and the "Logout" option disappears from the options list.
3. **Given** the confirmation prompt is shown, **When** the user cancels, **Then** the session remains active and nothing changes.
4. **Given** the user has just logged out, **When** they continue using the app, **Then** previously set local preferences (such as language) remain exactly as they were, and all guest-accessible features keep working.

---

### Edge Cases

- What happens if the user backs out of sign-in (started from the guest prompt) without completing it? Settings should remain in the guest view with no error state.
- What happens if the device denies location permission specifically on the Qibla Compass screen (rather than never having been asked)? The screen must explain why location is needed and offer a way to grant/retry, not silently fail.
- What happens if compass sensor accuracy degrades again after initially being good (mid-session)? The calibration prompt should reappear.
- What happens if the user changes the language while the Qibla Compass or a language-triggering bottom sheet is open? The change should still apply cleanly without leaving the UI in a mixed-language state.
- What happens if network/session sync fails right after login (profile fetch or preference pull)? The account section should still show at least the locally available name/email rather than reverting silently to the guest view.
- What happens if a guest taps "Prayer Times" or "Qibla Compass"? Both must work fully without requiring sign-in, since only Logout is authentication-gated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Settings screen MUST display an account section and a settings options list, in that order.
- **FR-002**: The account section MUST show a guest-state view when no user is signed in, explaining that signing in will save the user's data to an account, and offering a way to start sign-in.
- **FR-003**: The account section MUST show the signed-in user's name and email when a user is authenticated, replacing the guest-state view.
- **FR-004**: The account section MUST reflect a change in authentication state (guest → signed in, or signed in → guest) without requiring the user to leave and re-enter the Settings screen.
- **FR-005**: The settings options list MUST include, in order: Prayer Times, Qibla Compass, Change Language, and — only when the user is authenticated — Logout.
- **FR-006**: Selecting "Prayer Times" MUST navigate the user to the existing Prayer Times screen.
- **FR-007**: Selecting "Qibla Compass" MUST open the Qibla Compass screen.
- **FR-008**: Selecting "Change Language" MUST open a bottom sheet offering exactly two language choices: Arabic and English.
- **FR-009**: The language bottom sheet MUST visibly indicate which of the two languages is currently active.
- **FR-010**: Selecting a language in the bottom sheet MUST apply the app's locale and layout direction (right-to-left for Arabic, left-to-right for English) immediately, without an app restart.
- **FR-011**: The selected language MUST persist across app restarts.
- **FR-012**: "Prayer Times" and "Qibla Compass" MUST be reachable by both guest and authenticated users.
- **FR-013**: "Logout" MUST only be shown and reachable when the user is authenticated.
- **FR-014**: Selecting "Logout" MUST show a confirmation step before ending the session.
- **FR-015**: Confirming logout MUST end the authenticated session, return the account section to the guest-state view, remove "Logout" from the options list, and leave locally stored preferences (e.g., language) unchanged.
- **FR-016**: Canceling the logout confirmation MUST leave the session and Settings screen unaffected.
- **FR-017**: After logout, all guest-accessible functionality (including Prayer Times and Qibla Compass) MUST continue to work exactly as it does for a first-time guest.
- **FR-018**: The Qibla Compass screen MUST compute the bearing to the Kaaba using the user's current coordinates and render a live compass indicator that updates as the device's heading changes.
- **FR-019**: The Qibla Compass screen MUST detect low compass sensor accuracy and display a calibration prompt (figure-eight motion guidance) until accuracy improves, hiding the prompt once accuracy is sufficient.
- **FR-020**: On a device without a magnetometer, the Qibla Compass screen MUST show the Qibla bearing as a static degree value together with a message explaining why a live compass isn't available.
- **FR-021**: The Qibla Compass screen MUST handle unavailable location access by explaining that location is required and providing a way to grant/retry access, rather than failing silently.
- **FR-022**: Starting sign-in from the guest-state prompt MUST take the user into the existing sign-in flow; on successful sign-in, the user's preferences known to the app MUST be reconciled using the most recently updated version (local vs. remote).

### Key Entities

- **Account/Profile Info**: The identity data shown in the account section — display name and email — and whether the current session is a guest or an authenticated one.
- **Language Preference**: The user's chosen app language (Arabic or English), including the layout direction it implies, and whether it is currently applied.
- **Qibla Reading**: The computed bearing to the Kaaba for the user's current location, the live device heading (when a magnetometer is available), and the current sensor accuracy/calibration state.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can determine whether they are signed in or browsing as a guest within 2 seconds of opening Settings, with no additional taps.
- **SC-002**: A user can change the app's language and see the entire app's text and layout direction reflect the new language in under 2 seconds, with no app restart.
- **SC-003**: On a device with a working compass sensor and location access, the Qibla direction indicator becomes live and responsive to device movement within 3 seconds of opening the Qibla Compass screen.
- **SC-004**: A signed-in user can log out, with the app remaining fully usable in guest mode immediately afterward and zero loss of previously set local preferences.
- **SC-005**: 100% of sessions where the user is authenticated show a name and email in the account section that match the signed-in account's actual profile data.
- **SC-006**: Users on a device without a magnetometer, or without location access, are always shown a clear explanation instead of a broken or blank Qibla Compass screen.

## Assumptions

- The sign-in/sign-up flow itself (screens, credential handling) already exists in the app; this feature only needs to provide the entry point (guest prompt CTA, Logout) into and out of that existing flow — it does not redesign sign-in/sign-up.
- The Prayer Times screen already exists; this feature adds a navigation entry point to it only.
- Exactly two languages are supported app-wide: Arabic and English. The language bottom sheet does not need to accommodate additional languages.
- "Saving data to an account" in the guest prompt is informational messaging about the benefit of signing in — it is not a separate opt-in toggle or setting.
- Device location and motion-sensor permission requests follow the same user-facing pattern already used elsewhere in the app (e.g., for prayer times), rather than introducing a new permission-request pattern.
- Preference reconciliation on login (local vs. remote, most-recently-updated wins) is an existing behavior of the sign-in flow that this feature relies on as a postcondition, not something it newly implements.
- Logout requires a single confirmation step (confirm/cancel); no additional re-authentication or multi-step confirmation is required.
