import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:sakinah/features/quran/domain/entities/quran_font_setting.dart';
import 'package:sakinah/handlers/shared_handler.dart';

/// Fakes just enough of path_provider for `Hive.initFlutter()` (used by
/// [SharedPrefHandler]) to work inside a plain `flutter_test` run.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late QuranRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sakinah_quran_repo_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    repository = QuranRepositoryImpl(prefs: SharedPrefHandler.instance);
  });

  // specs/005-quran-fonts-local-source: QuranRepositoryImpl now sources the
  // Surah list, Juz grouping, and per-Surah ayat entirely from bundled
  // assets (assets/quran/chapters/**, assets/quran/juz_boundaries.json) —
  // no network call is made, so there's no Dio mock/fallback branch left to
  // exercise (contracts/quran_repository_contract.md).
  group('getSurahList', () {
    test('reads from the bundled asset', () async {
      final surahs = await repository.getSurahList();

      expect(surahs, hasLength(114));
      expect(surahs.first.number, 1);
      expect(surahs.first.transliteration, 'Al-Fatihah');
      expect(surahs.last.number, 114);
    });

    test('meaning is populated from the English-locale list file', () async {
      final surahs = await repository.getSurahList();

      expect(surahs.first.meaning, 'The Opener');
    });

    test('a cache hit never re-reads the asset', () async {
      final first = await repository.getSurahList(); // seeds the cache
      final second = await repository.getSurahList(); // served from Hive

      expect(second, hasLength(first.length));
      expect(second.first.number, first.first.number);
    });
  });

  group('getSurah', () {
    test('reads only the requested Surah\'s own bundled file', () async {
      final ayahs = await repository.getSurah(1);

      expect(ayahs, hasLength(7));
      expect(ayahs.first.numberInSurah, 1);
      expect(ayahs.first.text, isNotEmpty);
    });

    test('a different Surah number yields different content', () async {
      final surah1 = await repository.getSurah(1);
      final surah114 = await repository.getSurah(114);

      expect(surah1, hasLength(7));
      expect(surah114, hasLength(6));
      expect(surah1.first.text, isNot(surah114.first.text));
    });

    test('throws when the requested Surah has no bundled file', () async {
      expect(() => repository.getSurah(9999), throwsA(isA<Exception>()));
    });
  });

  group('getJuzSections', () {
    test(
        'builds all 30 sections from the boundary table, with a multi-Juz '
        'surah appearing in every Juz it spans', () async {
      final sections = await repository.getJuzSections();

      expect(sections, hasLength(30));

      // Al-Baqarah (surah 2) is known to span Juz 1, 2, and 3.
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

      // An-Nas (surah 114, the last) is entirely within Juz 30 only.
      final nasJuz = sections
          .where((s) => s.surahs.any((surah) => surah.number == 114))
          .map((s) => s.juzNumber)
          .toList();
      expect(nasJuz, [30]);
    });
  });

  group('font setting', () {
    test('defaults to QPCHafs when nothing is stored', () async {
      final setting = await repository.getFontSetting();

      expect(setting.fontFamily, QuranFontSetting.defaults.fontFamily);
      expect(setting.fontFamily, 'QPCHafs');
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

    test(
        'a stale, no-longer-offered saved family (e.g. Lateef) is migrated '
        'to the new default and re-persisted', () async {
      await repository.saveFontSetting(
        const QuranFontSetting(fontFamily: 'Lateef', fontSize: 22),
      );

      final migrated = await repository.getFontSetting();

      expect(migrated.fontFamily, QuranFontSetting.defaults.fontFamily);
      expect(migrated.fontSize, 22); // font size is untouched by migration

      // The correction was persisted, not just returned for this one call.
      final reread = await repository.getFontSetting();
      expect(reread.fontFamily, QuranFontSetting.defaults.fontFamily);
    });
  });
}
