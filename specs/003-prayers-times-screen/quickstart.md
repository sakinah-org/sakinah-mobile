# Quickstart: Validating the Prayers Times Screen

## Prerequisites

- New dependencies installed: `flutter pub add flutter_local_notifications timezone geocoding` (research.md R1/R3), then `flutter pub get`.
- A physical device or simulator/emulator with location services available (Coordinates flow) and notification permission resettable (iOS Settings / Android app-info "Notifications").
- Signed out (guest) and signed-in test accounts both available, to exercise sync scenarios.
- Run the app: `flutter run`.

## Reaching the screen

From Home, tap the edit/gear affordance on the prayer summary card (`PrayerTimesCard`), or navigate directly during development via `Navigator.pushNamed(context, AppRoutes.prayers)`.

## Scenario 1 — View today's prayer times (User Story 1, P1)

1. Grant location permission when prompted (or ensure it's already granted from a prior run).
2. Open the Prayers screen.
3. **Expect**: location card shows city, country, calculation method, and today's Hijri date; all five prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) list today's times in that order.
4. Turn on Airplane Mode, relaunch the app, reopen the Prayers screen.
5. **Expect**: previously-loaded times still display (fallback), not blank.
6. Fresh-install the app (or clear app storage) while offline, open the Prayers screen.
7. **Expect**: explicit "unable to load prayer times" state, no fabricated times.

## Scenario 2 — Control per-prayer notifications (User Story 2, P2)

1. On first visit with notification permission not yet requested, confirm the OS permission prompt appears before toggles are interactive.
2. Grant permission. Toggle Fajr's reminder off, then on.
3. **Expect**: the toggle's visual state updates immediately each time; restart the app and confirm Fajr's toggle still reflects the last change (Hive persistence).
4. While signed in, toggle Dhuhr off on Device A; on Device B (same account), reopen the Prayers screen.
5. **Expect**: Device B's Dhuhr toggle matches Device A's after reconciliation (verify via `select * from prayer_notification_settings where user_id = ...` in the Supabase dashboard/SQL editor — `updated_at` should reflect the most recent change).
6. Deny notification permission (first denial). Reopen the Prayers screen.
7. **Expect**: help card with an "Enable" control; tapping it opens device notification settings.
8. Deny permanently (deny twice on Android, or disable in iOS Settings). Reopen the Prayers screen.
9. **Expect**: persistent card explaining reminders can't be sent, "Enable" opens device settings, all five toggles rendered visually disabled.
10. Re-enable permission in device settings, return to the app (resume, no full restart required).
11. **Expect**: toggles become interactive again without reopening the screen.

## Scenario 3 — All-off alert banner (User Story 3, P3)

1. With notification permission granted, turn all five prayer toggles off one by one.
2. **Expect**: as soon as the last one turns off, an alert card appears at the top of the screen stating reminders are off.
3. Turn any single prayer back on.
4. **Expect**: the alert card disappears immediately, no reload needed.

## Scenario 4 — Reminder delivery (UC-05, supports SC-006)

1. With a prayer's toggle on and permission granted, set the device clock so that prayer's time is ~11 minutes away (or temporarily point `NotificationHandler.scheduleReminder` at a near-future time in a debug build).
2. Keep the app in the foreground until the scheduled fire time.
3. **Expect**: an in-app/foreground notification banner appears at prayer_time − 10 minutes.
4. Repeat with the app backgrounded.
5. **Expect**: a device-level (system tray) notification appears at the same offset; tapping it opens the app to Home.

## Automated checks to run before calling this feature done

- `flutter analyze` — clean, no new lints.
- `flutter test test/features/prayers/` — new unit tests for `PrayerNotificationSettingsCubit` (mirroring `test/shared/prayer_times/prayer_times_cubit_test.dart`'s `bloc_test`/`mocktail` pattern) and the repository impl (mirroring `prayer_times_repository_impl_test.dart`), covering: default-all-enabled on first load, toggle persists + reschedules, guest never syncs, last-write-wins reconciliation (both directions), all-off banner derivation.
- Manual side-by-side comparison against the design reference (spec.md SC-007) for: default state, all-off alert state, permission-denied state, permission-permanently-denied state.
