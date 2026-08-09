# Quickstart: Validating the Home Page feature

Manual end-to-end validation guide once the feature is implemented (Phase 2+ `/speckit-tasks` → `/speckit-implement`). References `contracts/` and `data-model.md` instead of duplicating field/state details.

## Prerequisites

- `flutter pub get` (pulls the three new dependencies from research.md §12: `geolocator`, `hijri`, `share_plus`)
- iOS: location-permission usage string present in `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`). Android: `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION` present in `android/app/src/main/AndroidManifest.xml`.
- A device/simulator with location services available (for the primary Prayer Times path) and the ability to toggle airplane mode/network (for fallback scenarios).
- `env = 'dev'` in `lib/main.dart` is unrelated to this feature (AlAdhan/Al Quran Cloud base URLs are on `AppEndPoints`, not per-environment — research.md §11), so no `.env.*` changes are required to test this feature.

## Run

```
flutter run
```

Navigate to `AppRoutes.main` (or whatever screen currently precedes it in the auth flow) → the bottom nav's first ("Home") tab.

## Scenario 1 — Happy path (online, location granted)

1. Grant the location permission prompt when asked.
2. **Expect**: header shows a greeting (with your account's name if logged in, generic if guest), the current day name, and today's Hijri date (`contracts/prayer_times_cubit_contract.md` / data-model.md `PrayerTimesLoadedState`).
3. **Expect**: prayer card shows the correct next prayer name and a countdown ticking down every second in `h:mm:ss`, with a smooth per-second transition (research.md §8). The 5-prayer strip shows all five times, with the next one visually emphasized.
4. **Expect**: Ayah of Today card shows Arabic verse text + translation + surah/ayah reference, no "Cached" label.
5. Tap the gear icon on the prayer card. **Expect**: navigates to the `AppRoutes.prayers` placeholder (research.md §6) — confirms the single-tap entry point (SC-007).
6. Tap "Share" on the Ayah card. **Expect**: native share sheet opens with the ayah text.

## Scenario 2 — Same-day reopen (Ayah caching, FR-011)

1. Force-close and relaunch the app the same day.
2. **Expect**: the exact same Ayah of Today is shown (no new network call — verify via network logs from `DioClient`'s existing request/response logging interceptor).

## Scenario 3 — Offline with prior successful loads (fallback, FR-007/FR-013)

1. With Scenario 1 already completed once (so caches exist), enable airplane mode.
2. Relaunch the app / reopen Home.
3. **Expect**: prayer times still display (from cache), no crash, no blank state.
4. **Expect**: Ayah of Today displays the last cached ayah with a visible "Cached" indicator (`AyahOfTodayLoadedState(isFromToday: false)`).

## Scenario 4 — Offline with no cache at all (fresh install + airplane mode)

1. Fresh install, enable airplane mode before first launch, open Home.
2. **Expect**: prayer card area shows the explicit "unable to load prayer times" / "set your location" state (`PrayerTimesUnavailableState`/`PrayerTimesLocationRequiredState`) — never blank or zeroed times.
3. **Expect**: Ayah card shows "Ayah of Today is unavailable. Check your internet connection." with a "Retry" button (`AyahOfTodayUnavailableState`).
4. Disable airplane mode, tap "Retry" on the Ayah card. **Expect**: ayah loads successfully.

## Scenario 5 — Location permission denied

1. Fresh install, deny the location permission prompt.
2. **Expect**: `PrayerTimesLocationRequiredState` guidance UI, with a retry/"enable location" action (research.md §4).

## Scenario 6 — Long ayah layout (FR-015/SC-006)

1. Force (via a debug/dev toggle, or by repeatedly retrying until the RNG lands on one) a long ayah, e.g. Al-Baqarah 282 (global ayah number can be computed offline: it's the longest ayah in the Quran).
2. **Expect**: the Ayah card grows and the page scrolls; no clipped text, no overlap with the bottom nav or other cards.

## Scenario 7 — Prayer boundary rollover (Edge Case, FR-005)

1. With the app open on the Home tab, wait for (or simulate by adjusting device clock forward) the countdown reaching `0:00:00`.
2. **Expect**: emphasis and countdown automatically move to the next prayer within ~5 seconds (SC-002), without manual refresh.
3. Repeat with device clock set just after Isha. **Expect**: next prayer shown is tomorrow's Fajr, not an error/blank state (Edge Case).

## Scenario 8 — Locale + theme parity (FR-018/SC-008)

1. Toggle locale EN ⇄ AR via `SettingsCubit.toggleLocale()` (existing Settings screen action). **Expect**: layout mirrors RTL⇄LTR; all UI chrome (greeting, "Next prayer"/"until adhan", prayer names, "Verse of the Day"/"Share") translates; the Ayah's Arabic verse text itself stays RTL in both locales.
2. Toggle dark mode via `SettingsCubit.toggleDarkMode()`. **Expect**: colors match the dark-theme mock (gradient card, surface/border tokens) — side-by-side comparison against the design reference (SC-008).

## Automated coverage (per constitution Principle VIII)

- `test/shared/prayer_times/prayer_times_cubit_test.dart` — `bloc_test` covering all 5 states in `contracts/prayer_times_cubit_contract.md`, using a fake `PrayerTimesRepository`.
- `test/shared/prayer_times/prayer_times_repository_impl_test.dart` — `mocktail`-faked `DioClient`/`SharedPrefHandler`/`LocationHandler` covering: fresh success, network failure with cache, network failure without cache, location denied.
- `test/features/home/ayah_of_today_cubit_test.dart` — `bloc_test` covering all 4 states in `contracts/ayah_of_today_cubit_contract.md`.
- `test/features/home/ayah_repository_impl_test.dart` — covering: same-day cache hit (no network call asserted), stale-cache-on-failure, no-cache-on-failure (throws → Cubit maps to unavailable).
