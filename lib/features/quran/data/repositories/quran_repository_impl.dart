import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../configurations/app_end_points.dart';
import '../../../../configurations/app_errors.dart';
import '../../../../configurations/app_persistence_data_keys.dart';
import '../../../../handlers/shared_handler.dart';
import '../../../../network/network_handler.dart';
import '../../../../network/request_instructions.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/juz_section.dart';
import '../../domain/entities/quran_font_setting.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../models/ayah_model.dart';
import '../models/quran_font_setting_model.dart';
import '../models/surah_model.dart';

/// See contracts/quran_repository_contract.md. Local-first,
/// fetch-once-reuse-forever (research.md R2) — Surah/Juz/Ayah content is
/// permanently static, so a cache hit skips the network entirely rather
/// than revalidating on any schedule.
class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    DioClient? dioClient,
    SharedPrefHandler? prefs,
  })  : _dio = dioClient ?? DioClient.instance,
        _prefs = prefs ?? SharedPrefHandler.instance!;

  final DioClient _dio;
  final SharedPrefHandler _prefs;

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  static const String _bundledAssetPath = 'assets/quran/quran_uthmani.json';

  Map<String, dynamic>? _bundledJsonCache;

  Future<Map<String, dynamic>> _loadBundledJson() async {
    if (_bundledJsonCache != null) return _bundledJsonCache!;
    final raw = await rootBundle.loadString(_bundledAssetPath);
    _bundledJsonCache = jsonDecode(raw) as Map<String, dynamic>;
    return _bundledJsonCache!;
  }

  @override
  Future<List<Surah>> getSurahList() async {
    if (_prefs.contains(AppPersistenceDataKeys.quranSurahListCache)) {
      final raw =
          _prefs.get<List>(key: AppPersistenceDataKeys.quranSurahListCache);
      return SurahModel.listFromHiveJson(raw);
    }

    try {
      final response = await _dio.request(RequestInstructions(
        url: AppEndPoints.quranCloudSurahList(),
        method: 'GET',
      ));
      final surahs = SurahModel.listFromAlQuranCloudJson(
          response.data as Map<String, dynamic>);
      await _prefs.save(
        AppPersistenceDataKeys.quranSurahListCache,
        value: SurahModel.listToHiveJson(surahs),
      );
      return surahs;
    } on DioException catch (e) {
      log('QuranRepositoryImpl.getSurahList network failed, '
          'falling back to bundled asset: $e');
      try {
        final bundled = await _loadBundledJson();
        final surahs = SurahModel.listFromBundledJson(bundled);
        // Cached too — content is static, so there's no reason to keep
        // retrying the network (and eating its timeout) on every call.
        await _prefs.save(
          AppPersistenceDataKeys.quranSurahListCache,
          value: SurahModel.listToHiveJson(surahs),
        );
        return surahs;
      } catch (_) {
        throw Failure.handleDioException(e);
      }
    }
  }

  @override
  Future<List<Ayah>> getSurah(int surahNumber) async {
    final cacheKey =
        '${AppPersistenceDataKeys.quranSurahCachePrefix}_$surahNumber';
    if (_prefs.contains(cacheKey)) {
      final raw = _prefs.get<List>(key: cacheKey);
      return AyahModel.listFromHiveJson(raw);
    }

    try {
      final response = await _dio.request(RequestInstructions(
        url: AppEndPoints.quranCloudSurah(surahNumber),
        method: 'GET',
      ));
      final ayahs = AyahModel.listFromAlQuranCloudJson(
          response.data as Map<String, dynamic>);
      await _prefs.save(cacheKey, value: AyahModel.listToHiveJson(ayahs));
      return ayahs;
    } on DioException catch (e) {
      log('QuranRepositoryImpl.getSurah($surahNumber) network failed, '
          'falling back to bundled asset: $e');
      try {
        final bundled = await _loadBundledJson();
        final surahs = bundled['surahs'] as List;
        final match = surahs.cast<Map>().firstWhere(
              (s) => s['number'] == surahNumber,
              orElse: () => const {},
            );
        if (match.isEmpty) throw Failure.handleDioException(e);
        final ayahs =
            AyahModel.listFromBundledJson(Map<String, dynamic>.from(match));
        await _prefs.save(cacheKey, value: AyahModel.listToHiveJson(ayahs));
        return ayahs;
      } catch (_) {
        throw Failure.handleDioException(e);
      }
    }
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
      try {
        juzToSurahNumbers = await _fetchJuzGroupingLive();
      } on DioException catch (e) {
        log('QuranRepositoryImpl.getJuzSections network failed, '
            'falling back to bundled asset: $e');
        try {
          final bundled = await _loadBundledJson();
          juzToSurahNumbers = _buildJuzGroupingFromBundled(bundled);
        } catch (_) {
          throw Failure.handleDioException(e);
        }
      }
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

  /// Fetches all 30 Juz endpoints in parallel and groups each one's ayahs by
  /// `surah.number` (research.md R3) — only the distinct surah numbers per
  /// Juz are kept, not the full ayah text, since that's all the Juz tab
  /// needs once resolved against the already-cached Surah list.
  Future<Map<int, List<int>>> _fetchJuzGroupingLive() async {
    final result = <int, List<int>>{};
    await Future.wait(List.generate(30, (i) => i + 1).map((juzNumber) async {
      final response = await _dio.request(RequestInstructions(
        url: AppEndPoints.quranCloudJuz(juzNumber),
        method: 'GET',
      ));
      final data = response.data as Map<String, dynamic>;
      final ayahs = (data['data'] as Map<String, dynamic>)['ayahs'] as List;
      final numbers = <int>{};
      for (final a in ayahs) {
        final surah = (a as Map)['surah'] as Map;
        numbers.add(surah['number'] as int);
      }
      result[juzNumber] = numbers.toList()..sort();
    }));
    return result;
  }

  /// Bundled-asset fallback: each ayah in the local dataset already carries
  /// its own `juz` number, so Juz grouping is derived without needing a
  /// separate bundled Juz dataset.
  Map<int, List<int>> _buildJuzGroupingFromBundled(
      Map<String, dynamic> bundled) {
    final result = <int, Set<int>>{};
    final surahs = bundled['surahs'] as List;
    for (final s in surahs) {
      final surahMap = s as Map;
      final surahNumber = surahMap['number'] as int;
      final ayahs = surahMap['ayahs'] as List;
      for (final a in ayahs) {
        final juz = (a as Map)['juz'] as int;
        result.putIfAbsent(juz, () => <int>{}).add(surahNumber);
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
      return QuranFontSettingModel.fromSupabaseRow(row);
    } catch (e) {
      log('QuranRepositoryImpl.fetchRemoteFontSetting failed: $e');
      return null;
    }
  }
}
