# Phase 1 Data Model: Home Page (Prayer Times & Ayah of Today)

Entities are grouped by owning module. "Domain entity" = what `presentation/` consumes; "Data model" = what the network/cache layer produces before mapping to the domain entity. Field names are illustrative Dart shapes, not final code.

## Shared module: `lib/shared/prayer_times/`

### `PrayerLocation` (domain entity — union)

Represents where prayer times are calculated for. A closed union so `PrayerTimesRepository.getPrayerTimes` has exactly one signature regardless of source (per the integration reference).

| Variant | Fields | Notes |
|---|---|---|
| `Coordinates` | `double latitude`, `double longitude` | Primary path this feature actually uses (device geolocation). |
| `City` | `String city` | Defined for forward-compatibility with the future Prayers manual-entry screen; not constructed anywhere in this feature (see research.md §5). |

### `CalculationMethod` (domain entity — enum)

| Value | Stored string | AlAdhan `method` id |
|---|---|---|
| `ummAlQura` | `umm_al_qura` | `4` (default when nothing is stored) |
| `isna` | `isna` | `2` |
| `mwl` | `mwl` | `3` |

### `PrayerTimes` (domain entity)

| Field | Type | Notes |
|---|---|---|
| `date` | `DateTime` | Gregorian date these timings apply to (device-local date the request was made for). |
| `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` | `DateTime` | Each combines `date` with the `HH:mm` from the AlAdhan response, in local time. |
| `nextPrayerCode` | `String` | One of `fajr\|dhuhr\|asr\|maghrib\|isha`; the *next* prayer chronologically from "now," rolling to tomorrow's `fajr` if `isha` has already passed today. Derived, not stored from the API. |
| `nextPrayerTime` | `DateTime` | The `DateTime` matching `nextPrayerCode` (may be tomorrow's Fajr). |

**Derivation rule** (FR-004/FR-005, Edge Case "all prayers passed"): `nextPrayerCode`/`nextPrayerTime` are computed by the Cubit each time `PrayerTimes` is loaded or the clock crosses a boundary — not persisted, since "now" changes constantly. When `now > isha` for today's `PrayerTimes`, the next prayer is tomorrow's Fajr, computed by requesting/deriving the following day's Fajr time.

### `CachedPrayerTimes` (data-layer envelope, persisted)

| Field | Type | Notes |
|---|---|---|
| `prayerTimes` | `PrayerTimesModel` (serialized) | The last successfully retrieved `PrayerTimes`. |
| `locationSignature` | `String` | Rounded lat/lng (or city name) the cached response was computed for — used only to decide whether a fresh fetch is warranted on location change, never to reject showing the fallback (FR-007 always allows showing *some* fallback regardless of location match). |
| `fetchedAt` | `DateTime` (ISO string) | When this response was retrieved — used for the "stale" distinction if ever surfaced in UI (not required by spec.md, kept for parity with the Ayah cache pattern). |

**Validation rules**:
- A `PrayerTimes` is only ever displayed as "live" when its `date` equals today's device-local date; otherwise it is the fallback path (FR-007) and, per spec.md's scope, no explicit "stale prayer times" label is required (unlike the ayah cache) — spec.md only requires *some* usable times or an explicit unable-to-load state.

## Feature: `lib/features/home/` (Ayah of Today)

### `AyahOfToday` (domain entity)

| Field | Type | Notes |
|---|---|---|
| `arabicText` | `String` | `data[0].text` from the Al Quran Cloud response (uthmani edition). |
| `translation` | `String` | `data[1].text` (en.sahih edition). |
| `surahNumber` | `int` | `data[0].surah.number`. |
| `surahName` | `String` | `data[0].surah.englishName` (Arabic surah display name is derived/localized in presentation, not stored separately — see Assumptions below). |
| `ayahNumberInSurah` | `int` | `data[0].numberInSurah`. |
| `globalAyahNumber` | `int` | The `{n}` (1–6236) used to fetch it — retained so a retry after a transient failure can be distinguished from a brand-new random pick if ever needed; not required by any FR but cheap to keep. |
| `selectedForDate` | `DateTime` | The calendar date (device-local) this ayah was chosen to represent "today" for — this is the cache/staleness key (FR-011/FR-012). |
| `isFromToday` | `bool` (derived, not stored) | `selectedForDate == today` — computed at display time, drives the "Cached"/stale-verse indicator (FR-013). |

**Validation rules**:
- `globalAyahNumber` MUST be generated client-side in `[1, 6236]` inclusive (FR per integration reference — global ayah index, not surah+in-surah pair).
- An `AyahOfToday` is only ever fetched fresh once per `selectedForDate` per device (FR-011/FR-012) — the repository checks the cache's `selectedForDate` before calling the network.

### `CachedAyah` (data-layer envelope, persisted)

| Field | Type | Notes |
|---|---|---|
| `ayah` | `AyahOfTodayModel` (serialized) | The most recently successfully fetched ayah, regardless of which day it was fetched for. |
| `fetchedForDate` | `DateTime` (ISO string) | Same as `AyahOfToday.selectedForDate` — read on load to decide cache-hit vs. stale vs. miss per spec.md's UC-06 main/alternate flows. |

## Presentation-only concepts (not persisted, no dedicated model file)

| Concept | Where it lives | Notes |
|---|---|---|
| Greeting period (morning/afternoon/evening) | `HomeGreetingHeader` widget, derived from `DateTime.now().hour` | Pure function of current time; localized strings via `TranslationKeys`. |
| Hijri date label | `date_time_extensions.dart` (`hijri` package under the hood) | Pure function of current Gregorian date; independent of `PrayerTimesCubit` (research.md §7). |
| Greeting name | `SessionCubit.instance.currentUser?.name` | `null`/guest → greeting renders without a name segment (FR-016: guests are fully supported). |

## State shapes (Cubit outputs — see contracts/ for the full public contract)

### `PrayerTimesState` (`lib/shared/prayer_times/presentation/bloc/prayer_times_state.dart`)

- `PrayerTimesInitialState` — before the first load attempt.
- `PrayerTimesLoadingState` — a fetch is in flight and no data (fresh or cached) is available yet to show meanwhile.
- `PrayerTimesLoadedState(PrayerTimes times, {required bool isFallback})` — `isFallback = true` when this came from cache rather than a fresh fetch (FR-007); UI does not need to visually distinguish this per spec.md (unlike the ayah's "Cached" badge), but the flag is threaded through for future use (e.g., the Prayers screen).
- `PrayerTimesLocationRequiredState` — no location available (fresh or cached) and none could be resolved (FR-009).
- `PrayerTimesUnavailableState({String? message})` — location is known but no fresh or cached times exist at all (FR-008).

### `AyahOfTodayState` (`lib/features/home/presentation/bloc/ayah_of_today_state.dart`)

- `AyahOfTodayInitialState`
- `AyahOfTodayLoadingState`
- `AyahOfTodayLoadedState(AyahOfToday ayah, {required bool isFromToday})` — `isFromToday = false` drives the "Cached" indicator (FR-013).
- `AyahOfTodayUnavailableState()` — no ayah fresh or cached at all; UI shows the retry affordance (FR-014).

## Entity relationship summary

```text
SessionCubit.currentUser ──(name, optional)──> HomeGreetingHeader
DateTime.now() ──(pure fns)──> HomeGreetingHeader (greeting period, Hijri date)

LocationHandler + PermissionHandler ──> PrayerLocation ──> PrayerTimesRepository
                                                              │
                                                              ├─> AlAdhan API (DioClient) ──> PrayerTimesModel ──> PrayerTimes
                                                              └─> SharedPrefHandler (CachedPrayerTimes) ──(fallback)──> PrayerTimes

PrayerTimesRepository ──> PrayerTimesCubit (singleton) ──> PrayerTimesState ──> PrayerTimesCard + PrayerDayStrip + PrayerTimesCountdown

AyahRepository ──(random 1-6236)──> Al Quran Cloud API (DioClient) ──> AyahOfTodayModel ──> AyahOfToday
                 └─> SharedPrefHandler (CachedAyah) ──(fallback)──> AyahOfToday

AyahRepository ──> AyahOfTodayCubit (scoped to HomePage) ──> AyahOfTodayState ──> AyahOfTodayCard
```
