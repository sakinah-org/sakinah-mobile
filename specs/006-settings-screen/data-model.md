# Data Model: Settings Screen

This feature adds no new backend tables. It extends two existing shared Cubits and introduces one new feature-local entity (`QiblaReading`) plus its accuracy state.

## 1. Account/Profile Info (existing — read-only for this feature)

Owned by `SessionCubit` (`lib/shared/bloc/session_cubit.dart`). Already models exactly what the spec needs:

| Field | Source | Used for |
|---|---|---|
| `SessionCubit.instance.isLoggedIn` | derived from `currentUser != null` | choosing guest vs. authenticated account-section view (FR-002/FR-003) |
| `SessionCubit.instance.currentUser` → `User { id, name, email }` (`lib/shared/models/user.dart`) | Hive-persisted session or live Supabase session | rendering name/email (FR-003) |

**New behavior added to `SessionCubit`** (see research.md R4):

```
Future<void> logout()
```

State transition: `authenticated (currentUser != null)` → `guest (currentUser == null)`.
Side effects: Supabase `signOut()`; clears only `isLogin`/`accessToken`/`refreshToken`/`userData` from `SharedPrefHandler`; emits `LoadedState(null)`. All other persisted keys (locale, dark mode, prayer location, notification settings, Quran font settings) are untouched — this is what guarantees FR-015/FR-017.

No new fields, no new persisted keys for this entity.

## 2. Language Preference (existing Cubit, extended)

Owned by `SettingsCubit` (`lib/shared/bloc/settings_cubit.dart`).

| Field | Type | Notes |
|---|---|---|
| `locale` | `Locale` | `Locale('ar')` or `Locale('en')` — the only two supported values (FR-008) |

**New behavior added to `SettingsCubit`**:

```
Future<void> setLocale(Locale locale)     // explicit selection from the bottom sheet
Future<void> loadPersistedSettings()      // startup hydration, called from main.dart
```

**New persisted key**: `AppPersistenceDataKeys.appLocale` (`String`, the `languageCode`, `'ar'`/`'en'`) — written by `setLocale`, read by `loadPersistedSettings`. Persists across restarts (FR-011).

State transition: `locale == X` → `setLocale(Y)` → `locale == Y`, `emit(LoadedState(locale))`. `MaterialApp`'s existing `BlocBuilder<SettingsCubit, AppStates>` (`lib/main.dart`) picks this up and rebuilds with the new `Locale`, flipping layout direction automatically via Flutter's RTL detection for `Locale('ar')` (FR-010).

No relationship to Account/Profile Info — language preference applies identically to guests and authenticated users (FR-012-equivalent for language, per UC-10 and research.md R9).

## 3. Qibla Reading (new — `lib/features/qibla/domain/entities/`)

Feature-local domain entity; not persisted (recomputed each time the screen is opened/heading changes).

```dart
sealed class QiblaReading {}

class QiblaLiveReading extends QiblaReading {
  final double bearingDegrees;   // qiblah/offset from QiblahDirection — angle to rotate to face the Kaaba
  final double headingDegrees;   // device heading from north (QiblahDirection.direction)
  final CompassAccuracy accuracy;
}

class QiblaStaticReading extends QiblaReading {
  final double bearingDegrees;   // computed via great-circle initial bearing (research.md R7), independent of any sensor
}

enum CompassAccuracy { unknown, low, good }
```

**Validation/derivation rules** (from FR-018–FR-021, research.md R7):

- `QiblaLiveReading` is only ever constructed when a magnetometer is available (`androidDeviceSensorSupport()` did not resolve `false`, and the heading stream is not reporting `null`) **and** the user's coordinates were resolved.
- `accuracy == CompassAccuracy.low` (or `.unknown`) drives the calibration-prompt UI (FR-019); it can flip back to `.good` on a later stream event without leaving the live-compass state.
- `QiblaStaticReading` is used whenever no magnetometer is available, regardless of accuracy (accuracy is meaningless without a live sensor).
- Neither variant is constructible without resolved coordinates — location-unavailable is a distinct state (below), not a `QiblaReading` value.

## 4. `QibiaCompassCubit` state (new — `lib/features/qibla/presentation/bloc/`)

Feature complexity warrants typed states per Constitution Principle II (multiple genuinely distinct UI branches), following the `[Feature][Status]State` convention:

| State | Meaning | UI |
|---|---|---|
| `QiblaInitialState` | not yet loaded | loading indicator |
| `QiblaLoadingState` | resolving location/sensor | loading indicator |
| `QiblaLiveState(QiblaLiveReading)` | live compass available | rotating dial + degree + calibration banner iff `accuracy != .good` |
| `QiblaStaticState(QiblaStaticReading)` | no magnetometer | static degree value + explanatory message (FR-020) |
| `QiblaLocationRequiredState` | coordinates unavailable | explanation + grant/retry action (FR-021) |

## Summary of touched persistence keys

| Key (new) | Owner | Value |
|---|---|---|
| `AppPersistenceDataKeys.appLocale` | `SettingsCubit` | `'ar'` \| `'en'` |

No other new persisted keys. `SessionCubit.logout()` only *removes* existing keys it already owns; it adds nothing new.
