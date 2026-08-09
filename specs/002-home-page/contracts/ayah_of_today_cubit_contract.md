# Contract: `AyahOfTodayCubit` (Home-scoped)

`lib/features/home/presentation/bloc/ayah_of_today_cubit.dart`

Unlike `PrayerTimesCubit`, this is **not** a singleton — it has exactly one consumer (`HomePage`) today, so it is constructed normally and provided via `BlocProvider` scoped to `HomePage`'s subtree, per Principle II ("do not make feature-local, per-screen state a singleton").

## Public API

```dart
Future<void> loadAyahOfToday();   // reads cache-or-fetches per the repository contract (ayah_of_today_api.md)
Future<void> retry();             // explicit user-triggered retry from the unavailable state (FR-014's "Retry" button)
```

`loadAyahOfToday()` is called once when `HomePage` builds. `retry()` is only reachable from `AyahOfTodayUnavailableState`'s UI.

## States emitted (see data-model.md for field shapes)

| State | When | Consumers do |
|---|---|---|
| `AyahOfTodayInitialState` | Before any load | Show `ShimmerContainer` in place of the ayah card. |
| `AyahOfTodayLoadingState` | Fetch in flight (including a manual retry) | Show `ShimmerContainer`. |
| `AyahOfTodayLoadedState(ayah, isFromToday)` | An ayah is available, fresh or cached | Render `AyahOfTodayCard` from `ayah`; when `isFromToday == false`, render the "Cached" indicator (FR-013) — a subtle label/timestamp, per spec.md. |
| `AyahOfTodayUnavailableState()` | No ayah available at all (no network, no cache) | Render `ayah_of_today_unavailable_view.dart`: the "Ayah of Today is unavailable. Check your internet connection." message + a "Retry" button wired to `retry()` (FR-014). |

## Layout responsiveness contract (FR-015/SC-006)

`AyahOfTodayCard` MUST size itself to `ayah.arabicText`/`ayah.translation` length without a fixed/clamped height — the card grows, the page scrolls (Home's content column is already vertically scrollable per the design mock's `overflow-y:auto` region). No consumer of this Cubit may assume a bounded ayah length.
