# Feature Specification: Prayers Times Screen

**Feature Branch**: `003-prayers-times-screen`

**Created**: 2026-08-09

**Status**: Draft

**Input**: User description: "Build the Prayers Times screen with two main components: (1) a location card showing city, country, calculation method, and the Hijri date, and (2) a list of the five daily prayers, each showing the prayer name, the reminder lead time, the prayer time, and an on/off toggle for that prayer's notification. When the user has disabled notifications for all five prayers, show an alert card at the top of the screen stating that prayer reminders are turned off. Reached from Settings or the edit affordance on Home's prayer summary. Users can grant or deny location/notification permissions, fall back to a manually selected city, and see graceful guidance when permissions are permanently denied. Each prayer's notification toggle persists locally, is synced to the user's account when signed in, and controls whether a reminder is scheduled 10 minutes before that prayer's time. Reminders are delivered as an in-app notification while the app is open and as a device-level notification otherwise."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See today's prayer times for my location (Priority: P1)

A user opens the Prayers screen and sees a location card (city, country, calculation method, Hijri date) followed by all five of today's prayers, each showing its name and exact time.

**Why this priority**: This is the screen's core, read-only purpose — knowing today's prayer schedule. Every other capability on this screen (notification toggles, alerts) is layered on top of a correctly displayed schedule, so it must work standalone first.

**Independent Test**: Can be fully tested by opening the Prayers screen with a resolved location and confirming the location card shows the correct city/country/calculation method/Hijri date and all five prayers show correct times for that location and date, independent of any notification-toggle behavior.

**Acceptance Scenarios**:

1. **Given** the user's location has already been resolved (detected via GPS or previously set manually) and a calculation method is configured, **When** the user opens the Prayers screen, **Then** the location card shows the city name, country name, the calculation method in use, and today's Hijri date, and all five prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) are listed with today's times for that location.
2. **Given** the device is offline and prayer times were previously loaded successfully, **When** the user opens the Prayers screen, **Then** the system shows the most recently retrieved prayer times rather than leaving the list empty.
3. **Given** the device is offline and no prayer times have ever been successfully retrieved, **When** the user opens the Prayers screen, **Then** the system shows an explicit "unable to load prayer times" state instead of blank or fabricated times.
4. **Given** no location has ever been resolved for the user (no GPS permission granted and no manual city selected), **When** the user opens the Prayers screen, **Then** the system shows guidance directing the user to configure a location instead of an empty or broken prayer list.
5. **Given** the user's Hijri date cannot be derived on their device, **When** the location card renders, **Then** the city, country, and calculation method still display correctly and the Hijri date element degrades gracefully rather than breaking the card.

---

### User Story 2 - Control per-prayer notification reminders (Priority: P2)

A user viewing the Prayers screen turns each prayer's reminder notification on or off independently, and that choice is remembered the next time they open the app.

**Why this priority**: This is the screen's primary interactive purpose and the reason a dedicated Prayers screen exists (versus the read-only summary on Home). It depends on Story 1's prayer list being visible but delivers the screen's main interactive value on its own.

**Independent Test**: Can be fully tested by toggling an individual prayer's notification on the Prayers screen, restarting the app, and confirming the toggle state and its underlying scheduled/cancelled reminder persisted, independent of the location card's content.

**Acceptance Scenarios**:

1. **Given** notification permission is already granted, **When** the user opens the Prayers screen, **Then** each of the five prayers shows its name, its time, a fixed "10 minutes before" reminder caption, and an On/Off toggle reflecting its current saved state.
2. **Given** a prayer's notification toggle is off, **When** the user turns it on, **Then** the new state is saved immediately, a reminder is scheduled for 10 minutes before that prayer's time, and — if the user is signed in — the change is synced to their account.
3. **Given** a prayer's notification toggle is on, **When** the user turns it off, **Then** the new state is saved immediately and any scheduled reminder for that prayer is cancelled.
4. **Given** the user is not signed in (guest), **When** they toggle a prayer's notification, **Then** the toggle still saves and takes effect locally, with no account sync attempted.
5. **Given** the user signs in on a device where local toggle values already exist, **When** account data becomes available, **Then** whichever of the local or remote value was changed most recently, per prayer, is the one applied and displayed.
6. **Given** notification permission has not yet been requested, **When** the user opens the Prayers screen for the first time, **Then** the system prompts for notification permission before the toggles become interactive.
7. **Given** notification permission was denied but not permanently, **When** the user opens the Prayers screen, **Then** the system shows a help message explaining that notifications are off with a control to try enabling permission again via device settings, and the toggles work normally once permission is granted and the user returns to the screen.
8. **Given** notification permission is permanently denied, **When** the user opens the Prayers screen, **Then** a persistent message explains reminders cannot be sent, provides a control that opens device notification settings, and all five toggles are shown in a visually disabled state until permission is granted.

---

### User Story 3 - See at a glance that all reminders are off (Priority: P3)

A user who has turned off every prayer's reminder sees a clear alert at the top of the Prayers screen confirming that no reminders will be sent, so they aren't left assuming reminders are still active.

**Why this priority**: This is a clarity/safety-net addition on top of Story 2's toggles — valuable so users aren't silently missing reminders they think are on, but the screen is fully usable without it since the individual toggle states already show the same information per-prayer.

**Independent Test**: Can be fully tested by turning off all five prayer notification toggles and confirming an alert card appears at the top of the screen, then turning any one back on and confirming the alert disappears — independent of the location card and of any specific prayer's time value.

**Acceptance Scenarios**:

1. **Given** all five prayers currently have their notification toggle off, **When** the Prayers screen is displayed, **Then** an alert card appears at the top of the screen stating that prayer reminders are turned off.
2. **Given** the all-off alert card is showing, **When** the user turns any single prayer's notification back on, **Then** the alert card is removed without requiring the screen to be reopened.
3. **Given** at least one prayer's notification is on, **When** the Prayers screen is displayed, **Then** no all-off alert card is shown.

---

### Edge Cases

- What happens the very first time a user (guest or newly signed-up) opens the Prayers screen with no prior toggle values anywhere? All five prayers default to notifications enabled.
- What happens if notification permission is revoked at the OS level after a reminder was already scheduled? The reminder silently fails to deliver; no error is shown to the user, and the app requests permission again on next launch.
- What happens if a user is signed in on two devices and changes the same prayer's toggle on both while offline, then both come online? The change with the later timestamp wins for that prayer; the other device's display updates to match on its next sync opportunity.
- What happens if the device's local date/timezone changes while the Prayers screen is open? Prayer times and the Hijri date reflect the corrected local time the next time they are recalculated, rather than silently showing stale values.
- What happens if the user reaches the Prayers screen with notification permission already permanently denied and no prayers were ever configured? The permanently-denied guidance is shown and toggles remain disabled; no all-off alert card is additionally shown since the toggle states themselves are inactive/unreadable in that state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST display a location card at the top of the Prayers screen showing the resolved city name, country name, the prayer-time calculation method currently in use, and today's Hijri date.
- **FR-002**: The system MUST display all five daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha), in that fixed order, each showing the prayer's name and its calculated time for today at the user's resolved location.
- **FR-003**: Each prayer entry MUST show a fixed reminder lead-time caption ("10 minutes before") and an On/Off toggle representing whether a reminder is scheduled for that prayer.
- **FR-004**: The system MUST persist each prayer's notification toggle value locally on the device immediately when changed, independent of sign-in state.
- **FR-005**: When a prayer's toggle is turned on, the system MUST schedule a reminder for 10 minutes before that prayer's time; when turned off, the system MUST cancel any reminder scheduled for that prayer.
- **FR-006**: When the user is signed in, the system MUST additionally sync each toggle change to the user's account; when the user is a guest, no account sync MUST be attempted and the toggle MUST still function fully from local storage.
- **FR-007**: When account data becomes available for a signed-in user (e.g., on login), the system MUST reconcile each prayer's local and account toggle value by keeping whichever was changed most recently, and MUST push any local value that has no counterpart yet on the account.
- **FR-008**: The system MUST show a persistent alert card at the top of the Prayers screen whenever all five prayers' notification toggles are off, and MUST remove it as soon as at least one toggle is on.
- **FR-009**: When prayer times cannot be freshly retrieved for today, the system MUST fall back to the most recently successfully retrieved prayer times, if any exist, rather than showing nothing.
- **FR-010**: When no prayer times are available at all (no fresh data and no fallback), the system MUST show an explicit "unable to load" state rather than blank, zeroed, or fabricated times.
- **FR-011**: When no location has ever been resolved for the user, the system MUST show guidance directing the user to configure a location rather than attempting to show prayer times.
- **FR-012**: When notification permission has not yet been requested, the system MUST prompt for it upon the user's first visit to the Prayers screen before the toggles become interactive.
- **FR-013**: When notification permission is denied (but not permanently), the system MUST show a help message explaining reminders are currently off, with a control that leads the user to grant permission, and MUST restore full toggle functionality once permission is granted.
- **FR-014**: When notification permission is permanently denied, the system MUST show a persistent explanatory message with a control that opens the device's notification settings, and MUST visually disable all five toggles until permission is granted.
- **FR-015**: The system MUST deliver a scheduled reminder as an in-app notification when the app is in the foreground, and as a device-level notification when the app is backgrounded or closed.
- **FR-016**: Tapping a delivered reminder notification MUST open the app to the Home screen.
- **FR-017**: If a reminder cannot be delivered because permission was revoked after it was scheduled, the system MUST fail silently to the user (no error shown) and MUST request notification permission again on the app's next launch.
- **FR-018**: The Prayers screen MUST be usable by both guest and authenticated users; viewing prayer times and toggling individual reminders MUST NOT require the user to be signed in.
- **FR-019**: The Prayers screen's visual presentation (location card, prayer list, toggles, alert and permission-guidance cards, spacing, iconography, and styling) MUST match the provided Sakinah design system reference for the Prayers screen.

### Key Entities

- **Prayer Notification Setting**: Per-prayer, per-user record of whether a reminder is enabled, the fixed reminder lead time, and when it was last changed — the basis for both local persistence and account sync/conflict resolution.
- **Prayer Times (for a day)**: The set of five named prayer start times (Fajr, Dhuhr, Asr, Maghrib, Isha) for a specific date and the user's resolved location; owned outside this feature but displayed by it.
- **Location/Calculation Preference**: The user's resolved location (detected or manually selected) and prayer-time calculation method; owned outside this feature but displayed and consumed by it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can see all five of today's prayer times and the location they apply to within 2 seconds of opening the Prayers screen.
- **SC-002**: Toggling a prayer's notification updates its visible state immediately and the choice survives an app restart 100% of the time in testing.
- **SC-003**: The all-off alert card appears within one screen update whenever the last enabled prayer is turned off, and disappears within one screen update when any prayer is turned back on, confirmed across at least 3 toggle cycles in manual testing.
- **SC-004**: 100% of Prayers screen visits show either live prayer times, clearly-labeled fallback prayer times, or an explicit "unable to load" message — never a blank or silently incorrect schedule.
- **SC-005**: A signed-in user's per-prayer toggle changes made on one device are reflected on a second device of theirs after that second device's next sync opportunity, verified for all five prayers in testing.
- **SC-006**: A user who denies notification permission is shown a clear explanation and a one-tap path to re-enable it, with no crash or blocked screen, in 100% of tested denial scenarios (first denial and permanent denial).
- **SC-007**: The implemented Prayers screen is visually indistinguishable from the provided design reference when compared side-by-side (spacing, color, type, iconography), across the default, all-off-alert, and permission-guidance states.

## Assumptions

- Location resolution (GPS permission prompts, manual city search, and the "permanently denied" help flow for *location* specifically) is owned by existing/shared app functionality also used by the Home screen; this feature consumes and displays the resolved location and calculation method rather than re-implementing how they are chosen.
- The five prayers' default notification state, for a user or guest with no prior saved value, is enabled (on).
- The reminder lead time is fixed at 10 minutes before each prayer's time for all users in this version; there is no per-prayer or per-user customization of that offset.
- "Signed in" account sync of toggle changes is best-effort and non-blocking: a failed sync does not roll back the local toggle and is retried on the next successful write or next login.
- The all-off alert card reflects only the app's own per-prayer reminder toggles; it is distinct from, and does not replace, the separate device notification-permission guidance cards described for denied/permanently-denied permission states.
- The Prayers screen is reached from an existing entry point (Settings, or an edit affordance on Home's prayer summary) that is owned outside this feature; this spec covers the screen's own content and behavior only.
- Visual/pixel parity with the design reference is treated as a hard acceptance bar (SC-007), evaluated by manual side-by-side comparison rather than automated visual regression tooling.
