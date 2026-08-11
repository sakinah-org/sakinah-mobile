# Contract: `QuranRepository` / `QuranRepositoryImpl`

`lib/features/quran/domain/repositories/quran_repository.dart` (interface)
`lib/features/quran/data/repositories/quran_repository_impl.dart` (implementation)

Local-first, fetch-once-reuse-forever (research.md R2) — unlike `PrayerTimesRepository`/`AyahRepository`, nothing here has a "same day" or "same location" invalidation concept, because Quran text and metadata are permanently static.

## Public API

```dart
Future<List<Surah>> getSurahList();
// Returns the cached list if present (no network call). Otherwise fetches
// GET /surah, maps to List<Surah> (research.md R1, data-model.md), caches
// it permanently, and returns it. On fetch failure with no cache, falls
// back to the bundled local asset (research.md R4). Throws only if
// neither cache, network, nor bundled fallback can produce a result
// (FR-018) — callers map this to QuranUnavailableState.

Future<List<JuzSection>> getJuzSections();
// Returns the cached 30-entry list if present. Otherwise fetches all 30
// GET /juz/{n}/quran-uthmani calls in parallel, groups each by
// surah.number, resolves against getSurahList()'s already-cached Surah
// entities (never a reduced shape — FR-004), caches the combined result
// permanently, and returns it. Same fallback/failure behavior as above.

Future<List<Ayah>> getSurah(int surahNumber);
// Returns the cached ayat for this Surah if present. Otherwise fetches
// GET /surah/{surahNumber}/quran-uthmani, maps ayahs[] to List<Ayah>
// (data-model.md), caches it permanently under this Surah's own cache
// key, and returns it. Same fallback/failure behavior as above.

Future<QuranFontSetting> getFontSetting();
// Reads {fontFamily, fontSize} from local Hive keys, defaulting per
// data-model.md if unset. Never touches the network directly — remote
// reconciliation is a separate step (see below), called once at startup
// by QuranFontSettingsCubit, not on every read.

Future<void> saveFontSetting(QuranFontSetting setting, {String? userId});
// Always writes both Hive keys immediately. If userId is non-null
// (SessionCubit.instance.currentUser?.id), additionally — fire-and-forget,
// swallowing failures (same contract as
// PrayerNotificationSettingsRepositoryImpl.syncToRemote) — upserts
// {user_id, quran_font_family, quran_font_size} to user_preferences
// (research.md R8, data-model.md), never touching that row's other
// columns.

Future<QuranFontSetting?> fetchRemoteFontSetting(String userId);
// Selects this user's quran_font_family/quran_font_size from
// user_preferences. Returns null (not throw) if the row doesn't exist yet
// or the columns are unset, or on any Postgrest error — caller treats
// null as "nothing to adopt, keep the local value."
```

## Failure mapping

`DioException` from any of the three content fetches → `Failure.handleDioException(e)`, matching every other Dio-based repository in this codebase. Supabase `PostgrestException` from font-setting sync → swallowed and logged only (never surfaced to the UI), matching `PrayerNotificationSettingsRepositoryImpl`'s existing precedent for the exact same reason: local state is already applied, a sync failure must not roll it back or interrupt the user.

## Constructor DI (mirrors every other repository impl in this codebase)

```dart
QuranRepositoryImpl({
  DioClient? dioClient,
  SharedPrefHandler? prefs,
}) : _dio = dioClient ?? DioClient.instance,
     _prefs = prefs ?? SharedPrefHandler.instance!;
```
