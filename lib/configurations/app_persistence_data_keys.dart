abstract class AppPersistenceDataKeys {
  static const String isLogin = 'is_login';
  static const String userData = 'user_data';
  static const String token = 'user_token';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // ============================================================================
  // Prayer Times (lib/shared/prayer_times/)
  // ============================================================================
  static const String prayerLocationLat = 'prayer_location_lat';
  static const String prayerLocationLng = 'prayer_location_lng';
  static const String prayerCalculationMethod = 'prayer_calculation_method';
  static const String prayerTimesCache = 'prayer_times_cache';

  // ============================================================================
  // Ayah of Today (lib/features/home/)
  // ============================================================================
  static const String ayahOfTodayCache = 'ayah_of_today_cache';

  // ============================================================================
  // Prayer Location Display (lib/shared/prayer_times/)
  // ============================================================================
  static const String prayerLocationDisplay = 'prayer_location_display';

  // ============================================================================
  // Prayer Notification Settings (lib/features/prayers/)
  // ============================================================================
  static const String prayerNotificationSettings =
      'prayer_notification_settings';

  // ============================================================================
  // Quran (lib/features/quran/)
  // ============================================================================
  static const String quranSurahListCache = 'quran_surah_list_cache';
  static const String quranJuzSectionsCache = 'quran_juz_sections_cache';

  /// Bumped to _v2 for specs/009-quran-paged-reading (research.md R5): the
  /// bundled chapters/{n}.json now carries a `page` field per ayah, so a
  /// cache written under the old key (pre-update installs) would silently
  /// keep serving page-less ayahs forever. The old key is intentionally
  /// left orphaned, not migrated.
  static const String quranSurahCachePrefix = 'quran_surah_cache_v2';
  static const String quranFontFamily = 'quran_font_family';
  static const String quranFontSize = 'quran_font_size';

  // ============================================================================
  // Quran Paged Reading (lib/features/quran/) — specs/009-quran-paged-reading
  // ============================================================================
  static const String quranPageBoundariesCache = 'quran_page_boundaries_cache';

  // ============================================================================
  // Settings (lib/shared/bloc/settings_cubit.dart) — specs/006-settings-screen
  // ============================================================================
  static const String appLocale = 'app_locale';

  // ============================================================================
  // Dark Mode (lib/shared/bloc/settings_cubit.dart) — specs/008-dark-mode
  // ============================================================================
  static const String isDarkMode = 'is_dark_mode';
}
