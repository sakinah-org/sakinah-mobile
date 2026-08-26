# Phase 0 Research: Dark Mode

No `NEEDS CLARIFICATION` markers remain in the Technical Context — this feature closes a well-understood gap in already-existing code rather than introducing new technology. The items below record the investigation that made that possible.

## R1: Do dark theme colors already exist, or do they need to be sourced from the design system?

**Decision**: Reuse the existing `AppColors.dark*` tokens as-is. No new colors are introduced.

**Rationale**: `lib/utils/style/app_colors.dart` already defines a complete dark palette — `darkBg`, `darkSurface`, `darkSurfaceRaised`, `darkTextPrimary/Secondary/Tertiary`, `darkBorder/BorderStrong`, `darkBrandPrimary/Dark/Medium/Light`, `darkOnBrand` — and `lib/utils/style/app_theme.dart` already composes them into a full `darkTheme` `ThemeData` (colorScheme, appBarTheme, button themes, card/dialog/input/chip/snackbar/drawer/tab themes). Both were authored in prior feature work and already match the project's "Color & Theme Board" design-system naming convention (light/dark semantic pairs). `MaterialApp` in `lib/main.dart` already wires `theme: lightTheme, darkTheme: darkTheme, themeMode: ...`. Re-deriving these values from the design source referenced in this feature's UI guide would duplicate work already done and risks drift from the tokens every other themed screen already renders with.

**Alternatives considered**: Re-fetching the Claude Design project referenced in the feature's UI guide to re-verify exact hex values. Rejected — the values in `app_colors.dart` are already the single source of truth per Constitution Principle IV ("UI code MUST NOT hardcode colors... consume styles only from this folder"), and FR-008 ("dark colors follow the design system") is satisfied by construction as long as the feature keeps consuming these existing tokens rather than introducing new ones.

## R2: Where should the toggle live, and what should it look like?

**Decision**: A new `SettingsToggleTile` widget, added as a row inside the same rounded/divided options-list container in `SettingsPage` that already holds Prayer Times / Qibla Compass / Change Language.

**Rationale**: `SettingsOptionTile` (the existing row widget) is navigational — icon, label, optional trailing value, chevron, `onTap` that pushes/opens something. A dark-mode row needs a `Switch`, not a chevron-driven navigation, so it isn't a drop-in reuse of `SettingsOptionTile`. The app already has exactly this shape of control in `PrayerReminderTile` (`lib/features/prayers/presentation/widgets/prayer_reminder_tile.dart`): a `Switch(value: ..., onChanged: ..., activeTrackColor: brandPrimary)` inside a themed row. `SettingsToggleTile` follows `SettingsOptionTile`'s icon-square + label layout (for visual consistency with its list siblings) but swaps the trailing chevron for a `Switch`, using the same `isDark ? darkX : lightX` color-resolution pattern both existing widgets already use.

**Alternatives considered**:
- Extending `SettingsOptionTile` with an optional `Switch` mode — rejected as it would overload one widget with two different interaction models (navigate vs. toggle) and two different trailing-affordance branches, adding a conditional that Principle V's "dedicated widget class" guidance argues against when the two roles are this distinct.
- A segmented control (Light/Dark) instead of a switch — rejected; spec.md explicitly frames this as a single toggle ("a toggle button"), and a `Switch` is the standard Flutter/Material affordance for a two-state on/off preference, consistent with the existing `PrayerReminderTile` precedent.

## R3: Icon for the toggle row

**Decision**: `AppIcons.appearance` (`assets/icons/appearance.svg`).

**Rationale**: This key already exists in `lib/utils/assets/app_icons_keys.dart` and the asset file already exists in `assets/icons/`, but neither is currently referenced anywhere in `lib/` (confirmed via search) — it was evidently added during a prior design import in anticipation of this exact row. Reusing it needs zero new asset work and matches Constitution Principle IV (every icon key added before use; this one already is).

**Alternatives considered**: Adding a new moon/sun icon. Rejected — unnecessary given an unused, purpose-fit icon already exists in the asset set.

## R4: Persistence mechanism and key

**Decision**: Add `AppPersistenceDataKeys.isDarkMode` and persist/restore it through the existing `SharedPrefHandler` (`lib/handlers/shared_handler.dart`, Hive-backed), exactly mirroring how `SettingsCubit.setLocale`/`loadPersistedSettings` already persist/restore `AppPersistenceDataKeys.appLocale`.

**Rationale**: `SharedPrefHandler` is the project's single local-persistence entry point (Constitution Principle VII) — "not raw `shared_preferences` or ad hoc `Hive.box()` calls." The spec's Assumptions section explicitly calls for reusing "the same local on-device storage mechanism already used for the existing language preference," and the existing `setLocale`/`loadPersistedSettings` pair in `settings_cubit.dart` is a direct, already-reviewed template for the read/write shape (`prefs.contains(key)` guard on load, `prefs.save(key, value: ...)` on write). Hive supports `bool` values natively, so no serialization/encoding step is needed beyond what `save`/`get<T>` already provide.

**Alternatives considered**: A separate `DarkModeCubit` or standalone persistence helper. Rejected — spec.md FR-009 explicitly requires theme state to go through "the app's existing settings state controller," and `SettingsCubit` already owns `isDarkMode` and `toggleDarkMode()`; the only gap is the missing persistence/hydration calls (see the pre-existing `// TODO` in `toggleDarkMode()` and the fact that `loadPersistedSettings()` only currently hydrates `locale`).

## R5: Default theme on first launch / missing preference

**Decision**: Default `isDarkMode = false` (light mode), unchanged from the current field default in `SettingsCubit`. `loadPersistedSettings()` only overwrites it when `AppPersistenceDataKeys.isDarkMode` is present in `SharedPrefHandler`.

**Rationale**: Directly satisfies FR-006 and edge case "cached theme preference is missing or unreadable → fall back to light." Mirrors the existing `locale` hydration guard (`if (prefs.contains(...))`), so a missing key is simply a no-op rather than a special case to handle.

**Alternatives considered**: Following `MediaQuery.platformBrightness`/system theme on first launch. Rejected per spec.md Assumptions — explicitly out of scope for this feature.
