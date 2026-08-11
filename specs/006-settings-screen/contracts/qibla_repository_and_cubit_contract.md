# Contract: `QiblaRepository` + `QiblaCompassCubit` (new — `lib/features/qibla/`)

## `QiblaRepository` (`domain/repositories/qibla_repository.dart`, implemented by `data/repositories/qibla_repository_impl.dart`)

```dart
abstract class QiblaRepository {
  /// Resolves user coordinates (via the shared LocationHandler/PermissionHandler,
  /// research.md R8) and returns a QiblaReading, or null if location is
  /// unavailable (permission denied / services off).
  Future<QiblaReading?> getBearing();

  /// True if the device has no usable magnetometer for a live compass
  /// (research.md R7). Checked once per screen visit before deciding
  /// whether to subscribe to the live streams.
  Future<bool> hasCompassSensor();

  /// Live stream of heading + accuracy updates, only meaningful when
  /// hasCompassSensor() == true. Cubit subscribes while the Qibla Compass
  /// screen is visible and cancels on dispose.
  Stream<QiblaLiveReading> watchLiveBearing();
}
```

Implementation notes (not part of the contract surface, for the tasks phase):
- `getBearing()`'s "location unavailable" `null` case reuses `PermissionHandler.checkLocationPermission()` + `LocationHandler.getCurrentPosition()`, matching `PrayerTimesRepositoryImpl.resolveLocation()`'s gating.
- `watchLiveBearing()` merges `FlutterQiblah.qiblahStream` (`QiblahDirection.offset` = bearing, `.direction` = heading) with `FlutterCompass.events` (`CompassEvent.accuracy`) into `QiblaLiveReading { bearingDegrees, headingDegrees, accuracy }` (research.md R7). A `null` `CompassEvent.heading` is treated as "no sensor," not as `0.0` (unlike `flutter_qiblah`'s own internal merge).
- The static-bearing branch computes `QiblaStaticReading.bearingDegrees` via the great-circle initial-bearing formula against the fixed Kaaba coordinates — no dependency on `flutter_qiblah`'s stream for this branch.

## `QiblaCompassCubit` (`presentation/bloc/qibla_compass_cubit.dart`)

Not a singleton — one consumer (`QiblaCompassPage`), constructed and provided per-screen via `BlocProvider` (Principle II: feature-local, per-screen state is not a singleton), same reasoning as `AyahOfTodayCubit`.

```dart
Future<void> load();     // called once when QiblaCompassPage builds
Future<void> retry();    // user-triggered retry from QiblaLocationRequiredState (FR-021)
```

### `load()` flow

1. `emit(QiblaLoadingState())`.
2. `hasCompassSensor()`:
   - `false` → resolve a `QiblaStaticReading` via `getBearing()`. If coordinates are unavailable, `emit(QiblaLocationRequiredState())`; else `emit(QiblaStaticState(reading))` (FR-020).
   - `true` → resolve initial coordinates via `getBearing()`. If unavailable, `emit(QiblaLocationRequiredState())` (FR-021); else subscribe to `watchLiveBearing()` and `emit(QiblaLiveState(reading))` on each event, deriving `accuracy` per-event (FR-018/FR-019).

### `retry()`

Re-runs the same flow as `load()` — used only from the `QiblaLocationRequiredState` UI's retry/grant-access action.

### States → UI (see data-model.md §4)

Calibration prompt visibility is derived per-emission from `QiblaLiveState.reading.accuracy != CompassAccuracy.good` — it is not a separate top-level state, so it can appear/disappear without a state-type change while the dial keeps rotating (edge case: "accuracy degrades again mid-session" from spec.md).
