# Contract: `QuranRepository` / `QuranRepositoryImpl` (updated)

`lib/features/quran/domain/repositories/quran_repository.dart` (interface — **unchanged** from `specs/004-quran-screen/contracts/quran_repository_contract.md`)
`lib/features/quran/data/repositories/quran_repository_impl.dart` (implementation — this contract supersedes 004's for the three content methods)

The public method signatures are identical to 004 — this is a data-layer-only change (research.md R5), matching the feature's architectural constraint that domain/presentation do not change. Only the internal sourcing of `getSurahList()`, `getJuzSections()`, and `getSurah(int)` changes; `getFontSetting()`, `saveFontSetting(...)`, and `fetchRemoteFontSetting(...)` are unchanged from 004 (still Hive + `user_preferences`, no bundled-asset or network involvement beyond the existing Supabase sync).

## Public API (signatures unchanged from 004)

```dart
Future<List<Surah>> getSurahList();
// Returns the cached list if present (no I/O at all). Otherwise reads and
// parses assets/quran/chapters/index.json (research.md R2/R4), maps to
// List<Surah> (data-model.md), caches it permanently in Hive, and returns
// it. No network call is ever made (research.md R1). Throws only if the
// bundled asset is missing or fails to parse (should not occur in
// practice — ships with the app) — callers map this to
// QuranUnavailableState, per spec.md FR-007.

Future<List<JuzSection>> getJuzSections();
// Returns the cached 30-entry list if present. Otherwise reads
// assets/quran/juz_boundaries.json (research.md R3/R4) and resolves it
// against getSurahList()'s already-cached Surah entities (their
// ayahCount) to compute each Juz's Surah membership (data-model.md),
// caches the combined result permanently, and returns it. No network
// call. Same failure behavior as above.

Future<List<Ayah>> getSurah(int surahNumber);
// Returns the cached ayat for this Surah if present. Otherwise reads and
// parses only assets/quran/chapters/$surahNumber.json (research.md
// R2/R4/R5 — never any other Surah's file), maps verses[] to List<Ayah>
// (data-model.md), caches it permanently under this Surah's own cache
// key, and returns it. No network call. Same failure behavior as above.

Future<QuranFontSetting> getFontSetting();
// Unchanged from 004, plus: validates the loaded fontFamily against
// QuranFontSetting.availableFontFamilies (now 4 entries — research.md
// R6); if it isn't a member, substitutes QuranFontSetting.defaults
// .fontFamily and re-persists the corrected value (research.md R7,
// spec.md FR-006) before returning.

Future<void> saveFontSetting(QuranFontSetting setting, {String? userId});
// Unchanged from 004.

Future<QuranFontSetting?> fetchRemoteFontSetting(String userId);
// Unchanged from 004, except: a remote value whose fontFamily isn't a
// member of the current availableFontFamilies (e.g. a pre-update user's
// 'Lateef') is treated the same as "no row"/"nothing to adopt" — returns
// null instead of the stale value, so it can never overwrite the caller's
// already-locally-migrated value (research.md R7). The stale row itself is
// corrected in user_preferences the next time that user explicitly changes
// their font setting (saveFontSetting's existing sync path), not
// proactively rewritten by a mere read.
```

## Failure mapping (changed)

There is no `DioException` path left in `getSurahList()`/`getJuzSections()`/`getSurah(int)` — no network call is made, so no Dio-specific error can occur there. A missing/corrupt bundled asset (defensive case only; these ship with the app and are verified at build/test time) is caught and re-thrown as `Failure.handleDioException`'s sibling generic path — `UnknownFailure`, matching how other repositories in this codebase surface a non-network internal error. Supabase `PostgrestException` handling for font-setting sync is unchanged from 004 (swallowed and logged only).

## Constructor DI

```dart
QuranRepositoryImpl({
  SharedPrefHandler? prefs,
}) : _prefs = prefs ?? SharedPrefHandler.instance!;
```

`DioClient` is no longer a constructor dependency of this repository (nothing in it makes an HTTP call anymore) — the `dioClient` parameter from 004's constructor is removed. `Supabase.instance.client` is still accessed directly for the font-setting sync methods, unchanged from 004.
