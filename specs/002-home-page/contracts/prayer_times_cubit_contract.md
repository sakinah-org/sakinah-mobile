# Contract: `PrayerTimesCubit` (shared, singleton)

`lib/shared/prayer_times/presentation/bloc/prayer_times_cubit.dart`

This is the **public contract** other code is allowed to depend on — Home today; a future Prayers settings screen and a future notification scheduler later (per the integration reference: "the notification scheduler (Bloc) should listen to this Cubit's state rather than call AlAdhan itself"). Widget code and other Blocs/Cubits MUST NOT call `PrayerTimesRepository` directly — always go through this Cubit.

## Access

```dart
PrayerTimesCubit.instance   // static, singleton — same pattern as SettingsCubit/UserCubit/SessionCubit
```

Provided at the widget-tree root via `BlocProvider` in `main.dart`, alongside `SettingsCubit`/`SessionCubit`.

## Public API

```dart
Future<void> loadPrayerTimes();     // triggers a load using the current stored/detected location + method
Future<void> refreshLocation();     // re-resolves device location (e.g. user tapped "enable location" retry), then loadPrayerTimes()
Future<void> onCalculationMethodChanged(CalculationMethod method);  // for the future Prayers screen; persists + refetches
```

`loadPrayerTimes()` is called by `HomePage` on first build (`BlocProvider`'s consumer, not by the Cubit auto-loading itself, so testing stays simple) and is safe to call repeatedly (idempotent given unchanged inputs — the repository's caching handles avoiding redundant network calls within the same day/location).

## States emitted (see data-model.md for field shapes)

| State | When | Consumers do |
|---|---|---|
| `PrayerTimesInitialState` | Before any load | Show a loading skeleton (`ShimmerContainer`) if this is the state on first Home build. |
| `PrayerTimesLoadingState` | Fetch in flight, nothing to show meanwhile | Show `ShimmerContainer` in place of the prayer card + strip. |
| `PrayerTimesLoadedState(times, isFallback)` | Fresh or cached times available | Render `PrayerTimesCard` + `PrayerDayStrip` from `times`; `isFallback` is not surfaced as a distinct visual per spec.md scope but is available. |
| `PrayerTimesLocationRequiredState` | No location resolvable at all | Render `prayer_times_unavailable_view.dart` in its "set location" variant (FR-009), with a retry action calling `refreshLocation()`. |
| `PrayerTimesUnavailableState({message})` | Location known, but no fresh/cached times exist | Render `prayer_times_unavailable_view.dart` in its "unable to load" variant (FR-008), with a retry action calling `loadPrayerTimes()`. |

## Refetch triggers (owned internally by the Cubit, not by callers)

- New calendar day (device-local) since the last successful load.
- Location changed (`refreshLocation()` resolves a different lat/lng than the cached one).
- Calculation method changed (`onCalculationMethodChanged`).

Home does not need its own polling/refresh logic — it only reacts to whatever `PrayerTimesCubit` emits, plus the second-by-second countdown recompute owned by `PrayerTimesCountdown` (contract: derived purely from `PrayerTimesLoadedState.times.nextPrayerTime` and `DateTime.now()`, no separate Cubit call per tick).
