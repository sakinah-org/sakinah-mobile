# Phase 0 Research: Settings Screen

## R1. Feature layering: UI-only Settings vs. business-logic Qibla

**Decision**: `lib/features/settings/` is a **UI-only** feature (Constitution Principle I) — `presentation/pages` + `presentation/widgets` only, no `domain/`/`data/`. `lib/features/qibla/` is a **business-logic** feature with the full Clean Architecture split (`domain/entities`, `domain/repositories`, `data/repositories`, `presentation/{bloc,pages,widgets}`).

**Rationale**: Settings only reads `SessionCubit`/`SettingsCubit` (both already exist in `lib/shared/bloc/`) and navigates — it owns no new data-fetching or domain rules, matching the `lib/features/main/ui/` reference example. Qibla Compass computes a bearing from device coordinates, tracks live sensor heading, and manages an accuracy/calibration state machine — genuine domain logic that doesn't belong inside a `presentation/`-only folder, and mirrors how `lib/shared/prayer_times/` and `lib/features/quran/` are structured.

**Alternatives considered**: A single `lib/features/settings/` folder housing Qibla as a subfolder — rejected because Settings and Qibla Compass are separately routed screens with unrelated domain logic; keeping Qibla as its own top-level feature matches the existing `prayers`/`quran` precedent and keeps Settings genuinely thin.

## R2. Reusing existing global state instead of new Cubits for the Settings screen itself

**Decision**: `SettingsPage` reads `SessionCubit.instance` (auth/profile state) and `SettingsCubit.instance` (locale/theme) directly via `BlocBuilder`/`context.watch` — no new Settings-scoped Cubit is introduced for the screen shell.

**Rationale**: Constitution Principle I requires checking `lib/shared/bloc/` before adding new state, and both cubits already model exactly what the account section and options list need (`SessionCubit.isLoggedIn`/`currentUser`, `SettingsCubit.locale`). `LoginBloc` already calls `SessionCubit.instance.persistSession(...)` on success (`lib/features/auth/presentation/bloc/login_bloc.dart:38`), so `BlocBuilder<SessionCubit, AppStates>` on the Settings page picks up a guest→authenticated transition automatically (satisfies FR-004) with zero new plumbing.

## R3. Extending `SettingsCubit` for explicit language selection + persistence

**Decision**: Extend `lib/shared/bloc/settings_cubit.dart` with:
- `Future<void> setLocale(Locale locale)` — sets `locale` directly (not a toggle) and persists it via `SharedPrefHandler`, then emits.
- `Future<void> loadPersistedSettings()` — reads any persisted locale/dark-mode at startup, called from `main.dart` before `runApp`, mirroring `QuranFontSettingsCubit.instance.load()` (`lib/main.dart:37`).
- A new `AppPersistenceDataKeys.appLocale` key.

`toggleLocale()`/`toggleDarkMode()` are left in place (grep confirms no other call sites — `main.dart` only reads `.isDarkMode`/`.locale`), but the language bottom sheet calls `setLocale()` since the user explicitly picks one of two rows rather than toggling blind.

**Rationale**: `MaterialApp` in `lib/main.dart` is already wrapped in `BlocBuilder<SettingsCubit, AppStates>` and reads `locale: SettingsCubit.instance.locale` — any `emit()` from `SettingsCubit` rebuilds `MaterialApp` with the new `Locale`, and Flutter's own RTL detection for `Locale('ar')` (via `supportedLocales`) handles the layout-direction flip for free. This directly satisfies FR-010 (immediate, no-restart locale + direction switch) with no new routing/rebuild mechanism. Only persistence (today's `// TODO: save the value in shared preferences`) and startup hydration are missing — both follow the exact `SharedPrefHandler`/`QuranFontSettingsCubit.load()` pattern already used elsewhere (Constitution Principle VII).

**Alternatives considered**: A new `LanguageCubit` — rejected as a duplicate state owner for something `SettingsCubit` already represents (Principle I says duplicating state with an existing home is a constitution violation).

## R4. `SessionCubit.logout()`

**Decision**: Add `Future<void> logout()` to `lib/shared/bloc/session_cubit.dart`: calls `supabase.Supabase.instance.client.auth.signOut()`, clears only the four session keys it owns (`isLogin`, `accessToken`, `refreshToken`, `userData`) from `SharedPrefHandler`, sets `_currentUser = null`, and emits `LoadedState(null)`.

**Rationale**: `SessionCubit` already imports `supabase_flutter` directly and is documented as "the only place that reads/writes session data in `SharedPrefHandler`" — logout is a session-data transition, so it belongs here, not in a new Settings-owned repository. It must clear only the session keys it owns and leave every other `SharedPrefHandler` key (locale, dark mode, prayer location, Quran font settings, notification settings) untouched, which is a natural consequence of only touching the four keys `SessionCubit` itself writes — directly satisfying FR-015/FR-017/SC-004.

**Alternatives considered**: Routing logout through `AuthRepository` (the Auth feature's interface) — rejected; `AuthRepository` is `lib/features/auth/domain/`, and Settings must not import another feature's domain layer (Principle I: features don't import each other directly). `SessionCubit` is the shared owner both already depend on.

## R5. Confirmation dialog for Logout

**Decision**: A standard Material `AlertDialog` (via `showDialog`), styled with existing `AppColors`/`AppTypography` tokens, with "Cancel" and a destructive-styled "Logout" action. No new shared dialog abstraction.

**Rationale**: No existing shared confirmation-dialog widget exists in `lib/shared/widgets/`; a single two-button `AlertDialog` is small enough to stay a private widget in `lib/features/settings/presentation/widgets/` per Principle V, matching how other one-off UI (e.g., `PrayerTimesUnavailableView`) is scoped to where it's used unless proven reusable elsewhere.

## R6. `flutter_qiblah` — bearing + heading

**Decision**: Add `flutter_qiblah` (`^3.1.0+1` — `^3.2.0` requires `geolocator ^14.0.2`, which conflicts with this project's existing `geolocator ^13.0.2`; `3.1.0+1` resolves cleanly) to `pubspec.yaml`. `QibiaRepositoryImpl` (in `lib/features/qibla/data/repositories/`) wraps:
- `FlutterQiblah.checkLocationStatus()` / `FlutterQiblah.requestPermissions()` for location gating (in addition to the existing `PermissionHandler.checkLocationPermission()` used elsewhere in the app, since `flutter_qiblah` needs location for its own bearing calculation).
- `FlutterQiblah.qiblahStream` → emits `QiblahDirection { qiblah, direction, offset }` (all `double`, degrees, 0–360, `direction` = device heading from north, `qiblah`/`offset` = angle to rotate to face the Kaaba). This drives the **live rotating dial** (FR-018).
- `FlutterQiblah.androidDeviceSensorSupport()` → `Future<bool>`, Android-only capability check, used as the primary "no magnetometer" signal (FR-020).

**Rationale**: This is the package the feature description explicitly names, is Android/iOS, and wraps the lower-level `flutter_compass_v2` + `geolocator` (already a project dependency) internally — no separate raw-sensor plumbing needed for the live-compass path.

**Constraint carried into tasks**: `flutter_qiblah` does not work on the iOS Simulator (real-device only) — manual QA for the live-compass paths must use a physical device.

## R7. Detecting low accuracy (calibration prompt) and the "no magnetometer" fallback

**Decision** (confirmed against the installed `flutter_qiblah 3.1.0+1` / `flutter_compass_v2 1.0.3` source):
- **Low accuracy**: `QiblahDirection { qiblah, direction, offset }` itself carries no accuracy field, so `QiblaRepositoryImpl` separately subscribes to `FlutterCompass.events` (`CompassEvent { heading, headingForCameraMode, accuracy }`, the transitive package `flutter_qiblah` already merges internally for its own stream) alongside the qiblah stream. `CompassEvent.accuracy` is the "deviation error in degrees, ± from the heading" (reliable on iOS; several hard-coded discrete values on Android). Treat `accuracy == null` or `accuracy > 15°` as low accuracy → show the calibration (figure-eight) prompt; hide it once a subsequent reading reports `accuracy <= 15°`. This threshold is a reasonable default to validate/tune during implementation, not a hard external spec.
- **No magnetometer**: if `androidDeviceSensorSupport()` resolves `false`, **or** a `CompassEvent.heading` comes back `null` (the documented Android no-sensor signal — `flutter_qiblah`'s own internal merge treats it as `0.0` via `event.heading ?? 0.0`, which our repository must not silently do, since that would masquerade as a real reading), switch to the static-bearing branch.
- **Static bearing fallback**: computed independently of the sensor stream via the standard great-circle initial-bearing formula between the user's resolved coordinates and the fixed Kaaba coordinates (21.422487°N, 39.826206°E — the exact constants `flutter_qiblah` itself uses internally, kept identical here so the static and live bearings never disagree). `flutter_qiblah`'s own equivalent helper (`Utils.getOffsetFromNorth`) is `src`-private and not exported by the package, so this formula must be reimplemented locally rather than called.

**Rationale**: Keeps the fallback path correct regardless of platform/plugin sensor-reporting quirks — the static bearing never depends on a sensor that might be absent.

## R8. Location gating for Qibla

**Decision**: Reuse `lib/handlers/location_handler.dart` (`LocationHandler.getCurrentPosition()`) and `lib/handlers/permission_handler.dart` (`PermissionHandler.checkLocationPermission()`) — the same handlers `PrayerTimesRepositoryImpl` already uses — for resolving the user's coordinates before computing any bearing (live or static). No new permission-request pattern is introduced (matches the spec's Assumptions section).

**Rationale**: Constitution Principle I / existing precedent; avoids a second location-permission code path with different UX from the one users already see on Prayers/Home.

## R9. Design reconciliation — guest view's options list

**Decision**: The imported design mock (`Sakinah Screens.dc.html`, §08 "Settings", GUEST · LIGHT/DARK figures) shows only two rows (Prayer Times, Qibla Compass) under the guest hero card — no "Change Language" row. The implementation will **add** a Change Language row to the guest options list, styled identically to the two existing rows (same list-row treatment used in the authenticated variant, including the current-language value shown on the trailing side).

**Rationale**: FR-005/FR-012 and UC-10 ("Actor: Guest / Authenticated") explicitly require language switching to be available to guests too; the mock's two-row guest list appears to be an incidental omission rather than a deliberate restriction (nothing in the design's descriptive copy or the rest of the spec suggests guests are meant to be locked to one language). Everything else about the guest view (hero card copy/art, list-row visual treatment, bottom-sheet content) follows the mock exactly.

## R10. Design tokens — no new design-system work needed

**Decision**: Confirmed via the imported design project's `tokens/colors.css` that every color used across the Settings, language-sheet, and Qibla-compass mocks (`--teal-900/700/600/300`, `--neutral-*`, `--bg`/`--surface`/`--surface-raised`, `--text-*`, `--border*`, `--brand-primary*`) already has a 1:1 counterpart in `lib/utils/style/app_colors.dart` (`AppColors.teal900`, `lightSurface`/`darkSurface`, etc.), and typography sizes/weights match the existing ad hoc `TextStyle` usage pattern seen in sibling features (e.g., `PrayerTimesUnavailableView`, `QuranFontSettingsSheet`). Existing icon keys already cover this feature's needs: `AppIcons.qibla`, `logOut`, `language`, `profile`, `chevronRight`, `close`, `location`, `clock`. No new colors, typography tokens, or icon assets are required.

## R11. Screen composition & routing

**Decision**:
- `AppRoutes.qiblaCompass = '/qibla-compass'` added to `lib/navigation/app_routes.dart`; a `case` added to `generateRoute()` for `QiblaCompassPage`.
- `MainPage`'s third `PageView` child (currently a placeholder `Container()` for the "Settings" bottom-nav tab, `lib/features/main/ui/pages/main_page.dart:17`) is replaced with `SettingsPage()`. Settings stays a **tab**, not a pushed route (matching the existing Home/Quran tabs), so it needs no `AppRoutes` entry of its own.
- The language bottom sheet is opened via `showModalBottomSheet` from `SettingsPage`, following the exact `QuranFontSettingsSheet.show(context)` pattern (`lib/features/quran/presentation/widgets/quran_font_settings_sheet.dart:24`).

**Rationale**: Matches Constitution's documented navigation approach (`Navigator` + `onGenerateRoute`, no `go_router`) and the precedent already set by the Quran font-settings sheet.
