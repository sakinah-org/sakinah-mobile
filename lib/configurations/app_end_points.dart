abstract class AppEndPoints {
  static const String apiKey = "2f4b89b9da7a48889d3615dde4f8bd6f";

  // ============================================================================
  // AlAdhan (Prayer Times) — fixed public host, unrelated to AppEnv.baseUrl
  // ============================================================================
  static const String alAdhanBaseUrl = "https://api.aladhan.com/v1";

  static String alAdhanTimingsByCoordinates(String date) =>
      "$alAdhanBaseUrl/timings/$date";

  static String alAdhanTimingsByCity(String date) =>
      "$alAdhanBaseUrl/timingsByCity/$date";

  // ============================================================================
  // Al Quran Cloud (Ayah of Today) — fixed public host
  // ============================================================================
  static const String quranCloudBaseUrl = "https://api.alquran.cloud/v1";

  static String quranCloudAyah(int globalAyahNumber) =>
      "$quranCloudBaseUrl/ayah/$globalAyahNumber/editions/quran-uthmani,en.sahih";

  // ============================================================================
  // Supabase tables (lib/features/prayers/) — not REST paths, but centralized
  // here per Principle VII rather than inlined as magic strings.
  // ============================================================================
  static const String prayerNotificationSettingsTable =
      'prayer_notification_settings';
}
