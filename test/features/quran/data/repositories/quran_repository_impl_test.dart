import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:sakinah/features/quran/domain/entities/quran_font_setting.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/network/network_handler.dart';

/// Fakes just enough of path_provider for `Hive.initFlutter()` (used by
/// [SharedPrefHandler]) to work inside a plain `flutter_test` run.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockDio dio;
  late QuranRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sakinah_quran_repo_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    await SharedPrefHandler.init();
    registerFallbackValue(Options());
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    dio = MockDio();
    when(() => dio.request(
          any(),
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionError,
    ));
    repository = QuranRepositoryImpl(
      dioClient: DioClient.instance..dio = dio,
      prefs: SharedPrefHandler.instance,
    );
  });

  group('getSurahList', () {
    test('falls back to the bundled asset when the network is unavailable',
        () async {
      final surahs = await repository.getSurahList();

      expect(surahs, hasLength(114));
      expect(surahs.first.number, 1);
      expect(surahs.first.transliteration, 'Al-Faatiha');
      expect(surahs.last.number, 114);
    });

    test('a cache hit never calls the network', () async {
      await repository.getSurahList(); // seeds the cache from bundled fallback

      final surahs = await repository.getSurahList();

      expect(surahs, hasLength(114));
      // Only the first call should have attempted the network at all — the
      // second must be served entirely from the permanent cache.
      verify(() => dio.request(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).called(1);
    });
  });

  group('getSurah', () {
    test('falls back to the bundled asset and returns the right ayah count',
        () async {
      final ayahs = await repository.getSurah(1);

      expect(ayahs, hasLength(7));
      expect(ayahs.first.numberInSurah, 1);
      expect(ayahs.first.text, isNotEmpty);
    });
  });

  group('getJuzSections', () {
    test(
        'builds all 30 sections from the bundled asset, with a multi-Juz '
        'surah appearing in every Juz it spans', () async {
      final sections = await repository.getJuzSections();

      expect(sections, hasLength(30));

      // Al-Baqara (surah 2) is known to span Juz 1, 2, and 3.
      final spanningJuz = sections
          .where((s) => s.surahs.any((surah) => surah.number == 2))
          .map((s) => s.juzNumber)
          .toList()
        ..sort();
      expect(spanningJuz, [1, 2, 3]);

      // Al-Faatiha (surah 1) is entirely within Juz 1 only.
      final fatihaJuz = sections
          .where((s) => s.surahs.any((surah) => surah.number == 1))
          .map((s) => s.juzNumber)
          .toList();
      expect(fatihaJuz, [1]);
    });
  });

  group('font setting', () {
    test('defaults when nothing is stored', () async {
      final setting = await repository.getFontSetting();

      expect(setting.fontFamily, QuranFontSetting.defaults.fontFamily);
      expect(setting.fontSize, QuranFontSetting.defaults.fontSize);
    });

    test('saveFontSetting persists and getFontSetting reads it back', () async {
      await repository.saveFontSetting(
        const QuranFontSetting(fontFamily: 'Amiri', fontSize: 24),
      );

      final setting = await repository.getFontSetting();

      expect(setting.fontFamily, 'Amiri');
      expect(setting.fontSize, 24);
    });
  });
}
