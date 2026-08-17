# Contract: AlAdhan Prayer Times API (external)

Consumed exclusively by `PrayerTimesRepositoryImpl` (`lib/shared/prayer_times/data/repositories/`). No other code calls these endpoints directly.

**Base URL**: `https://api.aladhan.com/v1` (constant on `AppEndPoints`, not `AppEnv` — see research.md §11)
**Auth**: none

## Request — coordinates (primary path used by this feature)

```
GET {base}/timings/{DD-MM-YYYY}?latitude={lat}&longitude={lng}&method={id}&school=0
```

| Param | Source | Notes |
|---|---|---|
| `{DD-MM-YYYY}` | Device local date, always explicit | Never omitted. |
| `latitude`/`longitude` | `PrayerLocation.Coordinates` (from `LocationHandler`/cache) | |
| `method` | `CalculationMethod` → int mapping (`umm_al_qura`→4, `isna`→2, `mwl`→3, `egyptian`→5) | Defaults to `umm_al_qura` (4) when nothing stored (research.md §4). |
| `school` | hardcoded `0` | No Hanafi toggle in v1. |

## Request — manual city (defined, not called in this feature)

```
GET {base}/timingsByCity/{DD-MM-YYYY}?city={city}&method={id}&school=0
```

`PrayerTimesRepository.getPrayerTimes` accepts a `PrayerLocation.City` and would route here, but nothing in this feature constructs a `City` value (research.md §5) — this path is exercised only once the future Prayers manual-entry screen exists.

## Response shape consumed

```json
{
  "data": {
    "timings": {
      "Fajr": "05:21", "Sunrise": "06:58", "Dhuhr": "12:12",
      "Asr": "15:11", "Maghrib": "17:25", "Isha": "19:02"
    },
    "date": { "gregorian": { "date": "01-12-2023" } }
  }
}
```

- Only `Fajr`, `Dhuhr`, `Asr`, `Maghrib`, `Isha` are read; `Sunrise`/`Imsak`/`Midnight`/`Firstthird`/`Lastthird`/`hijri`/`meta` are ignored.
- `date.gregorian.date` confirms which calendar date the timings apply to (used to validate the response matches the requested date).

## Repository contract

```
Future<PrayerTimes> getPrayerTimes({
  required PrayerLocation location,
  required CalculationMethod method,
  required DateTime date,
});
```

- On any `DioException` → `Failure.handleDioException`; a `ConnectionFailure`/`TimeoutFailure` triggers the cache-fallback path (see data-model.md `CachedPrayerTimes`); other failures propagate to the Cubit, which emits `PrayerTimesUnavailableState` if no cache exists either.
- On success, the repository persists a `CachedPrayerTimes` envelope before returning.

## Explicitly not called

`/qibla`, `/methods`, `/gToH`, `/hToG`, `/islamicHolidaysByHijriYear`, `/asmaAlHusna`.
