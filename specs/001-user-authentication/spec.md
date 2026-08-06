# Feature Specification: User Authentication (Login, Register, Forgot Password)

**Feature Branch**: `001-user-authentication`

**Created**: 2026-08-06

**Status**: Draft

**Input**: User description: "Feature ( Authentication ) : user will be able to ( login, register, forget-password ). 1. login -> user will enter his email and password, after the user login successfully the user will pop back to settings page. 2. register -> user will enter his name, email, password and confirm password, after the user register successfully the user will pop back to login. 3. forget-password -> this function will include 3 pages: first for entering email and press send (an OTP is sent to the email); second the user navigates to an OTP page, enters the OTP and presses verify (OTP length is 6 digits, with a resend option after a 1 minute countdown); last the user navigates to a reset-password page once the OTP is verified, enters new password and confirm password and presses send — on success the user navigates back to the login page. Logic guide: on successful login the app caches a logged-in flag, access token, refresh token, and user profile info locally, with the access and refresh tokens encrypted before caching; user profile info is fetched after a successful login and stored locally as well. On successful registration, pop back to login and show a success confirmation. On forgot-password, submitting the email triggers sending of an OTP; verifying the OTP navigates to reset-password; the resend cooldown resets to a fresh 1-minute countdown each time resend is used; on successful password reset, pop back to login with a success confirmation. Inputs are validated using the project's existing validation rules for email, password, confirm password, name, and OTP code. UI guide: pages should match a provided design reference (Sakinah design system) for login, register, forgot password, OTP, and reset password screens."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Returning user signs in (Priority: P1)

A user who already has an account opens the sign-in screen, enters their email and password, and gains access to their account so the app can recognize them on this and future visits.

**Why this priority**: Sign-in is the recurring, everyday entry point into the authenticated app experience. Every other authenticated capability in the app depends on this working correctly, and it is exercised far more often than registration or recovery.

**Independent Test**: Can be fully tested by entering valid credentials for an existing account and confirming the user is returned to the Settings screen in a recognized, signed-in state — deliverable and verifiable without register or forgot-password being built.

**Acceptance Scenarios**:

1. **Given** a user with a valid, registered email and password is on the login screen, **When** they enter their correct credentials and submit, **Then** the system signs them in, stores their session locally, and returns them to the Settings screen.
2. **Given** a user is on the login screen, **When** they submit with an incorrect password or an unregistered email, **Then** the system keeps them on the login screen and shows a clear error message without granting access.
3. **Given** a user is on the login screen, **When** they submit with an empty or invalid-format email, or an empty password, **Then** the system shows field-level validation messages and does not attempt to sign in.
4. **Given** a user has successfully signed in previously, **When** they relaunch the app, **Then** the system recognizes their signed-in state without requiring them to log in again.

---

### User Story 2 - New user creates an account (Priority: P2)

A person without an account opens the registration screen, provides their name, email, password, and password confirmation, and creates an account they can then sign in with.

**Why this priority**: Registration is the onboarding gateway for new users, but it is used once per user rather than repeatedly, and the app is only reachable by registered users once Story 1 (login) exists — so it is essential but secondary to login.

**Independent Test**: Can be fully tested by submitting a valid name, email, password, and matching confirmation on the registration screen and confirming a new account is created and the user lands back on the login screen with a success confirmation.

**Acceptance Scenarios**:

1. **Given** a person is on the registration screen, **When** they enter a valid name, a unique email, a valid password, and a matching confirmation, and submit, **Then** the system creates the account, returns them to the login screen, and displays a success confirmation.
2. **Given** a person is on the registration screen, **When** they submit an email that is already registered, **Then** the system shows a clear error and does not create a duplicate account.
3. **Given** a person is on the registration screen, **When** the confirmation password does not match the password, **Then** the system shows a validation error and does not submit the form.
4. **Given** a person is on the registration screen, **When** the name, email, or password fields are empty or fail the existing input rules, **Then** the system shows field-level validation messages and does not attempt to register.

---

### User Story 3 - User recovers a forgotten password (Priority: P3)

A user who cannot remember their password requests a reset by submitting their email, receives a one-time verification code, confirms it, and sets a new password to regain access to their account.

**Why this priority**: Password recovery is essential for account access continuity but is used far less frequently than login or registration, and the app remains usable for all other authenticated users without it being available on day one.

**Independent Test**: Can be fully tested end-to-end by submitting a registered email, entering the received 6-digit code, and setting a new password — confirming the user lands back on the login screen with a success confirmation and can subsequently log in with the new password.

**Acceptance Scenarios**:

1. **Given** a user is on the "forgot password" screen, **When** they submit a registered email, **Then** the system sends a 6-digit one-time verification code to that email and navigates the user to the OTP entry screen.
2. **Given** a user is on the OTP entry screen, **When** they enter the correct 6-digit code and press verify, **Then** the system confirms the code and navigates the user to the reset-password screen.
3. **Given** a user is on the OTP entry screen, **When** they enter an incorrect or expired code, **Then** the system shows a clear error and keeps them on the OTP screen without navigating forward.
4. **Given** a user is on the OTP entry screen and the 1-minute countdown has elapsed, **When** they press resend, **Then** the system sends a new code and restarts a fresh 1-minute countdown; before the countdown elapses, the resend option is not available.
5. **Given** a user has a verified OTP and is on the reset-password screen, **When** they enter a valid new password and matching confirmation and submit, **Then** the system updates their password, returns them to the login screen, and displays a success confirmation.
6. **Given** a user is on the reset-password screen, **When** the new password and confirmation do not match or fail the existing password rules, **Then** the system shows a validation error and does not submit the change.

---

### Edge Cases

- What happens when the network is unavailable or the identity service is unreachable during login, registration, OTP send/verify, or password reset? The system MUST show a clear, non-technical error and leave the user able to retry without losing entered data.
- What happens when a user tries to register with an email that is already registered? The system MUST reject the attempt with a clear message and not create a duplicate account.
- What happens when a user requests a password reset for an email that is not registered? The system MUST respond in a way that does not confirm or deny account existence, while still allowing the flow to proceed safely.
- What happens if the user backgrounds or closes the app mid-OTP-countdown and returns? The countdown MUST reflect real elapsed time rather than resetting, unless it has already expired.
- What happens if a user who is already signed in attempts to reach the login or register screens? The system MUST recognize the existing session rather than prompting for credentials again.
- What happens if the app is closed and reopened after a successful login? The cached session (logged-in state, tokens, user profile) MUST still be available so the user remains signed in.
- What happens when a user enters a code shorter than 6 digits, or non-numeric characters, in the OTP field? The system MUST block submission and show a validation message.
- What happens when a user presses resend repeatedly before the countdown finishes? The system MUST ignore the request and keep the existing countdown running.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow a user to sign in using an email and password.
- **FR-002**: System MUST validate the login email and password fields using the project's existing validation rules before attempting to sign in, and show a clear error when they are invalid.
- **FR-003**: System MUST reject sign-in attempts with incorrect credentials and inform the user without revealing which field (email or password) was wrong.
- **FR-004**: System MUST return the user to the Settings screen immediately after a successful login.
- **FR-005**: System MUST persist the user's signed-in state (a logged-in flag), access token, refresh token, and profile information locally so the session survives an app restart.
- **FR-006**: System MUST encrypt the access token and refresh token before they are stored locally; they MUST NOT be persisted in plain, readable form.
- **FR-007**: System MUST retrieve the authenticated user's profile information after a successful login and store it locally alongside the session.
- **FR-008**: System MUST expose the current signed-in/signed-out state so it can be checked consistently from anywhere in the app.
- **FR-009**: System MUST allow a person to register a new account by providing name, email, password, and password confirmation.
- **FR-010**: System MUST validate the name, email, password, and confirm-password fields using the project's existing validation rules, including that confirmation matches the password, before attempting to register.
- **FR-011**: System MUST reject registration when the submitted email is already associated with an existing account, and show a clear error.
- **FR-012**: System MUST return the user to the login screen and display a success confirmation immediately after successful registration.
- **FR-013**: System MUST allow a user to request password recovery by submitting their email address.
- **FR-014**: System MUST trigger delivery of a one-time verification code (OTP) to the submitted email upon a valid recovery request, and navigate the user to the OTP entry screen.
- **FR-015**: System MUST accept a 6-digit OTP on the OTP entry screen and validate its format using the project's existing validation rules before submission.
- **FR-016**: System MUST verify the submitted OTP and, when valid, navigate the user to the reset-password screen; when invalid or expired, MUST keep the user on the OTP screen and show a clear error.
- **FR-017**: System MUST disable the resend-OTP action for 1 minute after a code is sent, display the remaining countdown, and re-enable resend only once the countdown reaches zero.
- **FR-018**: System MUST, upon a resend request, send a new OTP and restart the countdown at a fresh 1 minute.
- **FR-019**: System MUST only allow access to the reset-password screen after the associated OTP has been successfully verified.
- **FR-020**: System MUST allow a user with a verified OTP to set a new password and confirmation, validated using the project's existing password and confirm-password rules.
- **FR-021**: System MUST update the account's password upon successful submission of a valid new password and confirmation.
- **FR-022**: System MUST return the user to the login screen and display a success confirmation immediately after a successful password reset.
- **FR-023**: System MUST present the login, register, forgot-password, OTP, and reset-password screens using the project's established visual design language, matching the provided design reference.

### Key Entities

- **User Account**: A registered person's identity in the system — name, email, and password (not stored or transmitted in the clear), created via registration and used for login and password recovery.
- **Authenticated Session**: The locally cached record of a signed-in user — a logged-in flag, an encrypted access token, an encrypted refresh token, and the associated user profile snapshot; persists across app restarts until the user signs out or the session is otherwise invalidated.
- **User Profile**: The authenticated user's descriptive information (e.g., name, email, and related account details) retrieved after login and cached alongside the session for local use.
- **Password Recovery Request**: A time-bound recovery attempt tied to a submitted email — includes the issued 6-digit OTP, its verification status, and the active resend countdown.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A returning user with correct credentials can complete sign-in and land back on the Settings screen in under 15 seconds under normal network conditions.
- **SC-002**: A new user can complete registration, from opening the form to seeing the success confirmation on the login screen, in under 2 minutes.
- **SC-003**: A user who forgets their password can regain account access — request code, verify code, set new password — in 3 steps or fewer, without needing outside support.
- **SC-004**: 100% of authentication tokens found in local app storage are encrypted; none are ever recoverable as plain readable text.
- **SC-005**: The OTP resend action remains unavailable for the full 1-minute cooldown in 100% of observed attempts, and becomes available immediately once the cooldown ends.
- **SC-006**: A previously signed-in user reopening the app is recognized as signed-in without re-entering credentials, in 100% of cases where the app was closed normally.
- **SC-007**: At least 95% of users entering correctly formatted credentials, registration details, or OTP codes are not blocked by incorrect validation errors.

## Assumptions

- The Settings screen already exists (or will exist independently of this feature) as the screen that initiates login and the screen the user returns to on success; building the Settings screen itself is out of scope here.
- Registered accounts are immediately usable after registration — no separate email-verification gate is required before a newly registered user can log in, since the description only calls for a success confirmation and a return to login.
- Each email address is associated with at most one account (standard uniqueness assumption for the registration flow).
- The OTP delivery channel is email, and the code is valid for a limited, system-determined window consistent with common one-time-code practice; exact expiry duration is an implementation detail left to the build phase.
- Field validation (email format, password strength/length, confirm-password match, name length, OTP format) follows the rules already established elsewhere in the project's validation logic, rather than introducing new rules for this feature.
- Signing out (ending an active session) is not part of this feature's described scope — this feature covers establishing a session (login), creating an account (register), and recovering access (forgot password); session termination may be addressed separately.
- Visual design for all five screens (login, register, forgot password, OTP, reset password) follows a single, previously defined design reference rather than being designed from scratch as part of this specification.
