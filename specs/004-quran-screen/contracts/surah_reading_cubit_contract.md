# Contract: `SurahReadingCubit` (feature-scoped)

`lib/features/quran/presentation/bloc/surah_reading_cubit.dart`

Not a global singleton — provided via `BlocProvider` scoped to `SurahReadingPage` only, one instance per screen visit (a fresh Surah number each time), per the feature brief's explicit instruction and Constitution Principle II.

## Access

```dart
BlocProvider(
  create: (_) => SurahReadingCubit(repository: QuranRepositoryImpl())
    ..loadSurah(surahNumber),
  child: const SurahReadingView(),
)
```

`surahNumber` comes from `ModalRoute.of(context)!.settings.arguments as int` (research.md R11), set by `QuranCubit`'s navigation call.

## Public API

```dart
Future<void> loadSurah(int surahNumber);
// Fetches (or reads cached) the Surah's own metadata via
// QuranRepository.getSurahList() (already cached from the browsing
// screen in the overwhelmingly common case — no extra network call) plus
// its ayat via QuranRepository.getSurah(surahNumber), and emits Loaded
// with both. Emits Unavailable only if the ayah fetch itself fails with
// no cache and no bundled fallback (FR-018) — a missing Surah-metadata
// lookup cannot happen since surahNumber always originates from an
// already-loaded Surah tap.
```

## States emitted (see data-model.md for field shapes)

| State | When | Consumers do |
|---|---|---|
| `SurahReadingInitialState` | Before `loadSurah()` call | Show a loading skeleton. |
| `SurahReadingLoadingState` | `loadSurah()` in flight | Keep skeleton. |
| `SurahReadingLoadedState(surah, ayahs)` | Ayat resolved | Render `ayahs` continuously with numbered badges (FR-010), styled per `QuranFontSettingsCubit.instance.state`'s current family/size (FR-011) — read directly, not passed through this Cubit. |
| `SurahReadingUnavailableState` | Neither remote nor bundled fallback produced this Surah's text | Render the explicit unable-to-load state (FR-018). |

## Relationship to `QuranFontSettingsCubit`

This Cubit does not hold or duplicate font state. The reading page composes two `BlocBuilder`s side by side: one on `SurahReadingCubit` (what ayat to show) and one on `QuranFontSettingsCubit` (how to style them) — exactly how the Prayers screen composes `PrayerNotificationSettingsCubit` alongside `PrayerTimesCubit.instance` without either owning the other's state.
