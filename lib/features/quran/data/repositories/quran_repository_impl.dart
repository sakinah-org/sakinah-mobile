import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../configurations/app_end_points.dart';
import '../../../../configurations/app_errors.dart';
import '../../../../configurations/app_persistence_data_keys.dart';
import '../../../../handlers/shared_handler.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/juz_section.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/quran_font_setting.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../models/ayah_model.dart';
import '../models/quran_font_setting_model.dart';
import '../models/surah_model.dart';

/// See contracts/quran_repository_contract.md
/// (specs/005-quran-fonts-local-source). Local-only, load-once-reuse-forever
/// (specs/004-quran-screen research.md R2, updated by
/// specs/005-quran-fonts-local-source research.md R1/R5) — Surah/Juz/Ayah
/// content is sourced entirely from bundled assets, never the network; a
/// cache hit skips even the asset read.
class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    SharedPrefHandler? prefs,
  }) : _prefs = prefs ?? SharedPrefHandler.instance!;

  final SharedPrefHandler _prefs;

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  static const String _chaptersIndexAssetPath =
      'assets/quran/chapters/index.json';
  static const String _juzBoundariesAssetPath =
      'assets/quran/juz_boundaries.json';
  static const String _pageBoundariesAssetPath =
      'assets/quran/page_boundaries.json';

  static String _chapterAssetPath(int surahNumber) =>
      'assets/quran/chapters/$surahNumber.json';

  Future<T> _loadAndDecode<T>(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return jsonDecode(raw) as T;
    } catch (e) {
      log('QuranRepositoryImpl: failed to load/parse $assetPath: $e');
      throw UnknownFailure('Unable to load Quran content ($assetPath)');
    }
  }

  @override
  Future<List<Surah>> getSurahList() async {
    if (_prefs.contains(AppPersistenceDataKeys.quranSurahListCache)) {
      final raw =
          _prefs.get<List>(key: AppPersistenceDataKeys.quranSurahListCache);
      return SurahModel.listFromHiveJson(raw);
    }

    final index = await _loadAndDecode<List>(_chaptersIndexAssetPath);
    final surahs = SurahModel.listFromBundledJson(index);
    await _prefs.save(
      AppPersistenceDataKeys.quranSurahListCache,
      value: SurahModel.listToHiveJson(surahs),
    );
    return surahs;
  }

  @override
  Future<List<Ayah>> getSurah(int surahNumber) async {
    final cacheKey =
        '${AppPersistenceDataKeys.quranSurahCachePrefix}_$surahNumber';
    if (_prefs.contains(cacheKey)) {
      final raw = _prefs.get<List>(key: cacheKey);
      return AyahModel.listFromHiveJson(raw);
    }

    final chapter = await _loadAndDecode<Map<String, dynamic>>(
        _chapterAssetPath(surahNumber));
    final ayahs = AyahModel.listFromBundledJson(chapter);
    await _prefs.save(cacheKey, value: AyahModel.listToHiveJson(ayahs));
    return ayahs;
  }

  /// Returns the cached 604-entry page→ayah-range index if present;
  /// otherwise reads and parses [_pageBoundariesAssetPath] (an object keyed
  /// by page number as a string — cached and returned as-is), caches it
  /// permanently, and returns it (contracts/quran_repository_paging_contract.md).
  Future<Map<String, dynamic>> _loadPageBoundaries() async {
    if (_prefs.contains(AppPersistenceDataKeys.quranPageBoundariesCache)) {
      return Map<String, dynamic>.from(
        _prefs.get<Map>(key: AppPersistenceDataKeys.quranPageBoundariesCache),
      );
    }

    final boundaries =
        await _loadAndDecode<Map<String, dynamic>>(_pageBoundariesAssetPath);
    await _prefs.save(
      AppPersistenceDataKeys.quranPageBoundariesCache,
      value: boundaries,
    );
    return boundaries;
  }

  @override
  Future<MushafPage> getPage(int pageNumber) async {
    final boundaries = await _loadPageBoundaries();
    final boundary = boundaries['$pageNumber'] as Map?;
    if (boundary == null) {
      throw ArgumentError.value(pageNumber, 'pageNumber', 'Must be 1–604');
    }
    final startSurahNumber = boundary['startSurah'] as int;
    final startAyah = boundary['startAyah'] as int;
    final endSurahNumber = boundary['endSurah'] as int;
    final endAyah = boundary['endAyah'] as int;

    final allSurahs = await getSurahList();
    final surahByNumber = {for (final s in allSurahs) s.number: s};

    // Almost always startSurahNumber == endSurahNumber (one run). Near the
    // end of the Quran, a page can span 3 short surahs at once (e.g. page
    // 604: Al-Ikhlas + Al-Falaq + An-Nas) — walk every surah in the
    // [startSurahNumber, endSurahNumber] range, not just the two ends.
    final runs = <MushafPageSurahRun>[];
    for (var surahNumber = startSurahNumber;
        surahNumber <= endSurahNumber;
        surahNumber++) {
      final ayahs = await getSurah(surahNumber);
      final isFirst = surahNumber == startSurahNumber;
      final isLast = surahNumber == endSurahNumber;
      final runAyahs = ayahs
          .where((a) =>
              (!isFirst || a.numberInSurah >= startAyah) &&
              (!isLast || a.numberInSurah <= endAyah))
          .toList();
      runs.add(
        MushafPageSurahRun(surah: surahByNumber[surahNumber]!, ayahs: runAyahs),
      );
    }

    return MushafPage(pageNumber: pageNumber, surahRuns: runs);
  }

  @override
  Future<int> firstPageOfSurah(int surahNumber) async {
    final ayahs = await getSurah(surahNumber);
    return ayahs.first.pageNumber!;
  }

  @override
  Future<int> firstPageOfJuz(int juzNumber) async {
    final rawBoundaries = await _loadAndDecode<List>(_juzBoundariesAssetPath);
    final boundaries =
        rawBoundaries.cast<Map>().map(Map<String, dynamic>.from).toList();
    final boundary = boundaries.firstWhere((b) => b['juz'] == juzNumber);
    final startSurah = boundary['startSurah'] as int;
    final startAyah = boundary['startAyah'] as int;

    final ayahs = await getSurah(startSurah);
    final ayah = ayahs.firstWhere((a) => a.numberInSurah == startAyah);
    return ayah.pageNumber!;
  }

  @override
  Future<List<JuzSection>> getJuzSections() async {
    Map<int, List<int>> juzToSurahNumbers;

    if (_prefs.contains(AppPersistenceDataKeys.quranJuzSectionsCache)) {
      final raw =
          _prefs.get<Map>(key: AppPersistenceDataKeys.quranJuzSectionsCache);
      juzToSurahNumbers = raw.map(
        (k, v) => MapEntry(int.parse(k as String), List<int>.from(v as List)),
      );
    } else {
      final allSurahs = await getSurahList();
      final boundaries = await _loadAndDecode<List>(_juzBoundariesAssetPath);
      juzToSurahNumbers = _buildJuzGroupingFromBoundaries(
        boundaries.cast<Map>().map(Map<String, dynamic>.from).toList(),
        allSurahs,
      );
      await _prefs.save(
        AppPersistenceDataKeys.quranJuzSectionsCache,
        value: juzToSurahNumbers.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    final allSurahs = await getSurahList();
    final surahByNumber = {for (final s in allSurahs) s.number: s};

    return [
      for (var juz = 1; juz <= 30; juz++)
        JuzSection(
          juzNumber: juz,
          surahs: (juzToSurahNumbers[juz] ?? const <int>[])
              .map((n) => surahByNumber[n])
              .whereType<Surah>()
              .toList(),
        ),
    ];
  }

  /// Walks the 114 Surahs (in canonical order, using each one's already
  /// known `ayahCount`) against the 30 static Juz boundary points
  /// (`assets/quran/juz_boundaries.json` — specs/005-quran-fonts-local-source
  /// research.md R3/data-model.md) to determine which Surah(s) each Juz
  /// spans — a Surah crossing a boundary is added to both the Juz it starts
  /// in and the Juz it continues into, reproducing the same grouping the
  /// old per-ayah `juz` field used to give directly.
  Map<int, List<int>> _buildJuzGroupingFromBoundaries(
    List<Map<String, dynamic>> boundaries,
    List<Surah> allSurahs,
  ) {
    final surahsByNumber = {for (final s in allSurahs) s.number: s};
    final result = <int, Set<int>>{for (var j = 1; j <= 30; j++) j: {}};

    for (var i = 0; i < boundaries.length; i++) {
      final juz = boundaries[i]['juz'] as int;
      final startSurah = boundaries[i]['startSurah'] as int;
      final startAyah = boundaries[i]['startAyah'] as int;

      final isLast = i == boundaries.length - 1;
      final endSurah = isLast ? 114 : (boundaries[i + 1]['startSurah'] as int);
      final endAyahExclusive =
          isLast ? null : (boundaries[i + 1]['startAyah'] as int);

      for (var surahNumber = startSurah;
          surahNumber <= endSurah;
          surahNumber++) {
        final ayahCount = surahsByNumber[surahNumber]?.ayahCount;
        if (ayahCount == null) continue;

        final rangeStart = surahNumber == startSurah ? startAyah : 1;
        final rangeEndExclusive =
            (surahNumber == endSurah && endAyahExclusive != null)
                ? endAyahExclusive
                : ayahCount + 1;

        if (rangeStart < rangeEndExclusive) {
          result[juz]!.add(surahNumber);
        }
      }
    }

    return result.map((k, v) => MapEntry(k, v.toList()..sort()));
  }

  @override
  Future<QuranFontSetting> getFontSetting() async {
    final fontFamily = _prefs.contains(AppPersistenceDataKeys.quranFontFamily)
        ? _prefs.get<String>(key: AppPersistenceDataKeys.quranFontFamily)
        : QuranFontSetting.defaults.fontFamily;
    final fontSize = _prefs.contains(AppPersistenceDataKeys.quranFontSize)
        ? _prefs.get<double>(key: AppPersistenceDataKeys.quranFontSize)
        : QuranFontSetting.defaults.fontSize;

    // A saved family that's no longer offered (e.g. a pre-update user's
    // 'Lateef') is treated as unset and migrated to the new default, then
    // re-persisted so the correction sticks (specs/005-quran-fonts-local-
    // source research.md R7, spec.md FR-006).
    if (!QuranFontSetting.availableFontFamilies.contains(fontFamily)) {
      final migrated = QuranFontSetting(
        fontFamily: QuranFontSetting.defaults.fontFamily,
        fontSize: fontSize,
      );
      await saveFontSetting(migrated);
      return migrated;
    }

    return QuranFontSetting(fontFamily: fontFamily, fontSize: fontSize);
  }

  @override
  Future<void> saveFontSetting(
    QuranFontSetting setting, {
    String? userId,
  }) async {
    await _prefs.save(AppPersistenceDataKeys.quranFontFamily,
        value: setting.fontFamily);
    await _prefs.save(AppPersistenceDataKeys.quranFontSize,
        value: setting.fontSize);

    if (userId != null) {
      unawaited(_syncFontSettingToRemote(setting, userId));
    }
  }

  Future<void> _syncFontSettingToRemote(
    QuranFontSetting setting,
    String userId,
  ) async {
    try {
      await _client.from(AppEndPoints.userPreferencesTable).upsert(
            QuranFontSettingModel.toSupabaseRow(setting, userId: userId),
            onConflict: 'user_id',
          );
    } catch (e) {
      log('QuranRepositoryImpl._syncFontSettingToRemote failed: $e');
    }
  }

  @override
  Future<QuranFontSetting?> fetchRemoteFontSetting(String userId) async {
    try {
      final row = await _client
          .from(AppEndPoints.userPreferencesTable)
          .select('quran_font_family, quran_font_size')
          .eq('user_id', userId)
          .maybeSingle();
      final setting = QuranFontSettingModel.fromSupabaseRow(row);
      // A remote value saved before this update (e.g. 'Lateef') is no
      // longer valid — treat it the same as "nothing to adopt" so it never
      // overwrites the caller's already-migrated local value (research.md
      // R7); the stale remote row is corrected on the user's next explicit
      // font change via saveFontSetting.
      if (setting != null &&
          !QuranFontSetting.availableFontFamilies.contains(
            setting.fontFamily,
          )) {
        return null;
      }
      return setting;
    } catch (e) {
      log('QuranRepositoryImpl.fetchRemoteFontSetting failed: $e');
      return null;
    }
  }
}
