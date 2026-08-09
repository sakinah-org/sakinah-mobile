# Contract: Al Quran Cloud Ayah API (external)

Consumed exclusively by `AyahRepositoryImpl` (`lib/features/home/data/repositories/`). No other code calls this endpoint directly.

**Base URL**: `https://api.alquran.cloud/v1` (constant on `AppEndPoints`)
**Auth**: none

## Request

```
GET {base}/ayah/{n}/editions/quran-uthmani,en.sahih
```

- `{n}`: a random integer in `[1, 6236]`, generated client-side in `AyahRepositoryImpl` — the global ayah index across the whole Quran (not a surah+in-surah pair).
- Both editions requested in one call; response order follows the edition order in the URL (`data[0]` = Arabic `quran-uthmani`, `data[1]` = English translation `en.sahih`).

## Response shape consumed

```json
{
  "data": [
    { "text": "...", "surah": { "number": 2, "englishName": "Al-Baqara" }, "numberInSurah": 255 },
    { "text": "...", "surah": { "number": 2, "englishName": "Al-Baqara" }, "numberInSurah": 255 }
  ]
}
```

Mapped to `AyahOfToday` (data-model.md): `data[0].text` → `arabicText`, `data[1].text` → `translation`, `data[0].surah.number` → `surahNumber`, `data[0].surah.englishName` → `surahName`, `data[0].numberInSurah` → `ayahNumberInSurah`.

## Repository contract

```
Future<AyahOfToday> getAyahOfToday();
```

No parameters — all cache/fallback logic is internal, per the integration reference:

1. Read `CachedAyah` from `SharedPrefHandler`. If `fetchedForDate == today` → return it, **no network call**.
2. Otherwise, generate a random `n` in `[1, 6236]` and call the endpoint above.
   - Success → persist a new `CachedAyah{ayah, fetchedForDate: today}`, return it with `isFromToday: true`.
   - Failure (`ConnectionFailure`/`TimeoutFailure` or any other) with an existing `CachedAyah` (any prior date) → return that cached ayah with `isFromToday: false` (drives the "Cached" indicator, FR-013).
   - Failure with **no** `CachedAyah` at all → throw; `AyahOfTodayCubit` catches this and emits `AyahOfTodayUnavailableState()` (FR-014). Per research.md §10, no local-Quran-asset fallback is implemented in this feature (that asset doesn't exist yet).

## Explicitly not called

`/surah`, `/juz`, `/edition`, `/search`, any audio CDN endpoint.
