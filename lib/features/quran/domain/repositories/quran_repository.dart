import '../entities/ayah.dart';
import '../entities/juz_section.dart';
import '../entities/quran_font_setting.dart';
import '../entities/surah.dart';

/// Local-first, fetch-once-reuse-forever (research.md R2) — Quran text and
/// metadata are permanently static, unlike the day/location-scoped caches
/// used elsewhere in this codebase. See contracts/quran_repository_contract.md.
abstract class QuranRepository {
  /// Returns the cached list if present (no network call); otherwise fetches,
  /// caches permanently, and returns it. Falls back to the bundled local
  /// asset on fetch failure with no cache. Throws only if neither cache,
  /// network, nor bundled fallback can produce a result (FR-018).
  Future<List<Surah>> getSurahList();

  /// Returns the cached 30-entry list if present; otherwise builds it (from
  /// the live Juz endpoints or, on failure, from the bundled asset's
  /// per-ayah `juz` numbers), caches it permanently, and returns it. Same
  /// fallback/failure behavior as [getSurahList].
  Future<List<JuzSection>> getJuzSections();

  /// Returns the cached ayat for this Surah if present; otherwise fetches,
  /// caches permanently under this Surah's own cache key, and returns it.
  /// Same fallback/failure behavior as [getSurahList].
  Future<List<Ayah>> getSurah(int surahNumber);

  /// Reads `{fontFamily, fontSize}` from local Hive, defaulting per
  /// [QuranFontSetting.defaults] if unset. Never touches the network.
  Future<QuranFontSetting> getFontSetting();

  /// Always writes both Hive keys immediately. If [userId] is non-null,
  /// additionally — fire-and-forget, swallowing failures — upserts to
  /// `user_preferences`, never touching that row's other columns.
  Future<void> saveFontSetting(QuranFontSetting setting, {String? userId});

  /// Selects this user's Quran font columns from `user_preferences`.
  /// Returns null (not throw) if the row doesn't exist yet, the columns are
  /// unset, or on any Postgrest error.
  Future<QuranFontSetting?> fetchRemoteFontSetting(String userId);
}
