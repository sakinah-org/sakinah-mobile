# Contract: `QuranCubit` (feature-scoped)

`lib/features/quran/presentation/bloc/quran_cubit.dart`

Not a global singleton — provided via `BlocProvider` scoped to `QuranPage` only (research.md R6). Owns the Surah list, the active tab, and search — one Cubit for all of it, per the feature brief's explicit instruction and Constitution Principle II.

## Access

```dart
BlocProvider(
  create: (_) => QuranCubit(repository: QuranRepositoryImpl())..loadSurahs(),
  child: const QuranView(),
)
```

## Public API

```dart
Future<void> loadSurahs();
// Fetches (or reads cached) Surah list via QuranRepository.getSurahList()
// and emits Loaded with activeTab = QuranTab.surah, juzSections empty,
// searchQuery/searchResults null. Emits Unavailable only if the
// repository itself throws (FR-018).

Future<void> switchTab(QuranTab tab);
// No-op if a search is currently active (FR-008's tab-switcher-disabled
// rule is enforced by the UI not calling this while searching, not by
// this method). When switching to QuranTab.juz for the first time this
// session, calls QuranRepository.getJuzSections() (only then — not
// eagerly on loadSurahs(), so opening the Surah tab alone never triggers
// the 30-Juz fetch) and emits Loaded with the populated juzSections and
// activeTab = juz. Switching back to QuranTab.surah is instant (no
// re-fetch — juzSections stays populated in state for the rest of the
// session).

void search(String query);
// Synchronous, in-memory only (research.md R7) — filters the current
// surahs list by arabicName/transliteration substring match
// (case-insensitive), emits Loaded with searchQuery = query and
// searchResults = the filtered list. activeTab/surahs/juzSections are
// unchanged (preserved so clearSearch() can restore them).

void clearSearch();
// Emits Loaded with searchQuery = null, searchResults = null, restoring
// whichever activeTab was active before the search began.
```

## States emitted (see data-model.md for field shapes)

| State | When | Consumers do |
|---|---|---|
| `QuranInitialState` | Before first `loadSurahs()` call | Show a loading skeleton. |
| `QuranLoadingState` | `loadSurahs()` in flight | Keep skeleton. |
| `QuranLoadedState(...)` | Surah list resolved | If `searchQuery != null`, render `searchResults` as a flat list and hide the tab switcher (FR-008); else render `surahs` (Surah tab) or `juzSections` (Juz tab) per `activeTab`. |
| `QuranUnavailableState` | Neither remote nor bundled fallback produced a Surah list | Render the explicit unable-to-load state (FR-018). |

## Relationship to `SurahReadingCubit` and `QuranFontSettingsCubit`

`QuranCubit` does not read or depend on either — tapping a Surah entry is a pure navigation action (`Navigator.pushNamed(context, AppRoutes.surahReading, arguments: surah.number)`), and the font-settings bottom sheet is opened independently of this Cubit (it reads `QuranFontSettingsCubit.instance` directly via its own `BlocBuilder`, not through `QuranCubit`).
