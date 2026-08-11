# Quickstart: Settings Screen Validation

Manual end-to-end checks, one per user story from `spec.md`. Run on a physical device for anything Qibla-related — `flutter_qiblah` does not work on the iOS Simulator (research.md R6).

## Prerequisites

- `flutter pub get` after `flutter_qiblah` is added to `pubspec.yaml`.
- A test account already registered (reuse specs/001-user-authentication's flow) for the authenticated scenarios.
- Device/simulator location permission reset to "ask every time" before the location scenarios, so the permission-prompt paths are actually exercised.

## US1 — Account status at a glance

1. Fresh install (or clear app storage), launch the app, go to the Settings tab. **Expect**: guest hero card ("Browsing as guest" copy) with a sign-in CTA, no name/email shown.
2. Tap the sign-in CTA → complete login with the test account → return to Settings (or land back on it if login redirects there). **Expect**: account section now shows the account's name and email, no app restart needed.
3. Force-quit and relaunch the app, open Settings. **Expect**: still shows the authenticated profile (session restored).

## US2 — Options list navigation

1. From Settings (either guest or authenticated), tap "Prayer Times". **Expect**: navigates to the existing Prayer Times screen.
2. Back out, tap "Qibla Compass". **Expect**: opens the Qibla Compass screen (see US4 below for its own checks).
3. Back out, tap "Change Language". **Expect**: language bottom sheet opens (see US3).
4. As a guest, confirm no "Logout" row is present anywhere in the list.
5. While authenticated, confirm a "Logout" row is present, visually separated at the bottom of the list.

## US3 — Language switching

1. Open the language bottom sheet. **Expect**: exactly two rows, Arabic and English, native name leading with the other language's gloss underneath; the currently active language shows the brand-border/check treatment.
2. Tap the language that is *not* currently active. **Expect**: sheet closes, all visible text switches language, and layout direction flips (RTL for Arabic, LTR for English) with no restart.
3. Relaunch the app. **Expect**: opens directly in the language just selected.
4. Reopen the sheet and tap the language that *is* already active. **Expect**: sheet closes, nothing else changes.

## US4 — Qibla direction

Physical device required for steps 1–2.

1. With location permission granted and a working magnetometer, open Qibla Compass. **Expect**: a live circular dial appears within ~3s and visibly rotates as the device is turned; a degree value and Kaaba-distance line are shown below it.
2. Deliberately induce a low-accuracy reading (common in practice: hold the device near a metal surface/magnet, or just after launch before the OS has a fix). **Expect**: a calibration prompt (figure-eight guidance) appears; move the device in a figure-eight until accuracy improves, then confirm the prompt disappears while the dial keeps working.
3. On a device/emulator reporting no magnetometer (or force `hasCompassSensor()` to return false in a debug build), open Qibla Compass. **Expect**: a static degree value with an explanatory message, no live dial.
4. Deny location permission, open Qibla Compass. **Expect**: a clear explanation plus a grant/retry action — no crash, no blank screen. Grant permission via the action and confirm it recovers into the live or static state as appropriate.

## US5 — Logout

1. While authenticated, note the current language and any other local preference. Tap "Logout". **Expect**: a confirmation prompt appears; nothing happens yet.
2. Tap Cancel. **Expect**: still authenticated, nothing changed.
3. Tap "Logout" again, confirm. **Expect**: account section reverts to the guest view, "Logout" row disappears, and the previously noted language preference is unchanged.
4. With the app now in guest mode, repeat US2 steps 1–3 (Prayer Times, Qibla Compass, Change Language) and confirm all still work exactly as for a first-time guest.

## Cross-cutting

- Toggle system light/dark mode (or the app's own theme, if wired) and re-check the guest hero card, authenticated profile card, options list, language sheet, and Qibla dial each render with the correct light/dark tokens from `AppColors` (both are present in the imported design mock for every screen in this feature).
