# Quickstart: Dark Mode Validation

Manual end-to-end checks, one per user story from `spec.md`. No physical-device-only dependency — pure Flutter theming, runs fine on simulator/emulator.

## Prerequisites

- `flutter pub get` (no new dependencies expected, but run for safety after `pubspec.yaml`/lockfile changes if any).
- Fresh install or cleared app storage for the "first launch" checks, so no stale `AppPersistenceDataKeys.isDarkMode` value is left over from development.

## US1 — Switch between light and dark theme

1. Launch the app in light mode (default), go to the Settings tab.
2. Confirm a theme toggle row is visible in the options list, showing the light state.
3. Tap the toggle. **Expect**: the entire app (current screen, `AppBar`, cards, buttons) switches to dark colors immediately — no navigation, no restart. The toggle itself now shows the dark state.
4. Navigate to another tab (e.g. Home, Quran) without restarting. **Expect**: it renders in dark mode too.
5. Return to Settings, tap the toggle again. **Expect**: everything switches back to light immediately, toggle shows light state.

## US2 — Theme choice persists across sessions

1. From light mode, toggle to dark mode on Settings.
2. Force-quit the app fully (not just background) and relaunch. **Expect**: app opens directly in dark mode — Settings toggle already shows dark on first frame, no flash of light theme.
3. Toggle back to light mode, force-quit, relaunch. **Expect**: opens in light mode.
4. Clear app storage (or fresh install) and launch for the first time. **Expect**: opens in light mode (default) with no prior toggle interaction.

## US3 — Every screen renders correctly in dark mode

With dark mode active (from US1/US2):

1. Visit each main tab (Home, Prayer Times, Quran, Settings). **Expect**: backgrounds/surfaces/text/icons use dark tokens throughout, text stays legible (no light-on-light or dark-on-dark text).
2. Open the language bottom sheet (Settings → Change Language) and the logout confirmation dialog (if signed in). **Expect**: both render with dark surfaces/text, not the light-mode appearance.
3. Open any Quran font-settings sheet or other modal reachable from the app. **Expect**: same — dark tokens applied, no leftover light-mode chrome.

## Edge cases

1. Rapidly tap the toggle 5+ times in quick succession. **Expect**: no flicker/crash; final visible state matches the last tap, and it's the state still shown after a relaunch.
2. Toggle the theme while the language bottom sheet is open. **Expect**: the open sheet updates to the new theme immediately, consistent with the rest of the app.

## Verification references

- Contract: [contracts/settings_cubit_dark_mode_contract.md](./contracts/settings_cubit_dark_mode_contract.md) — `SettingsCubit.toggleDarkMode()` / `loadPersistedSettings()` behavior.
- Data model: [data-model.md](./data-model.md) — Theme Preference field, persistence key, state transitions.
- Automated coverage: `bloc_test` cases for `toggleDarkMode()` persisting to `SharedPrefHandler` and `loadPersistedSettings()` hydrating `isDarkMode` from a stored value vs. defaulting to `false` when absent (see plan.md Testing).
