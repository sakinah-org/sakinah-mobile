import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/features/quran/domain/entities/quran_font_setting.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/presentation/bloc/quran_font_settings_cubit.dart';
import 'package:sakinah/features/quran/presentation/bloc/quran_font_settings_state.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/models/user.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockQuranRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp
        .createTemp('sakinah_quran_font_settings_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await AppEnv.init('dev');
    AESEncryptor.init();
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    repository = MockQuranRepository();
    registerFallbackValue(
      const QuranFontSetting(fontFamily: 'Lateef', fontSize: 20),
    );
  });

  group('load (guest)', () {
    blocTest<QuranFontSettingsCubit, QuranFontSettingsState>(
      'adopts the local value and never fetches remotely',
      setUp: () async {
        // No SessionCubit.persistSession call — currentUser stays null.
        await SessionCubit.instance.restoreSession();
        when(() => repository.getFontSetting()).thenAnswer(
          (_) async =>
              const QuranFontSetting(fontFamily: 'Amiri', fontSize: 24),
        );
      },
      build: () => QuranFontSettingsCubit.test(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<QuranFontSettingsLoadedState>()
            .having((s) => s.fontFamily, 'fontFamily', 'Amiri')
            .having((s) => s.fontSize, 'fontSize', 24),
      ],
      verify: (_) {
        verifyNever(() => repository.fetchRemoteFontSetting(any()));
      },
    );
  });

  group('setFontFamily / setFontSize (guest)', () {
    blocTest<QuranFontSettingsCubit, QuranFontSettingsState>(
      'updates state immediately and persists locally without a userId',
      setUp: () async {
        await SessionCubit.instance.restoreSession();
        when(() =>
                repository.saveFontSetting(any(), userId: any(named: 'userId')))
            .thenAnswer((_) async {});
      },
      build: () => QuranFontSettingsCubit.test(repository),
      act: (cubit) async {
        await cubit.setFontFamily('Nastaleeq');
        await cubit.setFontSize(28);
      },
      expect: () => [
        isA<QuranFontSettingsLoadedState>()
            .having((s) => s.fontFamily, 'fontFamily', 'Nastaleeq'),
        isA<QuranFontSettingsLoadedState>()
            .having((s) => s.fontSize, 'fontSize', 28),
      ],
      verify: (_) {
        verify(() => repository.saveFontSetting(
              any(that: isA<QuranFontSetting>()),
              userId: null,
            )).called(2);
      },
    );
  });

  group('load (authenticated)', () {
    setUp(() async {
      await SessionCubit.instance.persistSession(
        accessToken: 'a',
        refreshToken: 'r',
        user: User(id: 'u1', name: 'Test', email: 't@example.com'),
      );
    });

    blocTest<QuranFontSettingsCubit, QuranFontSettingsState>(
      'adopts a non-null remote value after the local emit',
      setUp: () {
        when(() => repository.getFontSetting()).thenAnswer(
          (_) async =>
              const QuranFontSetting(fontFamily: 'Lateef', fontSize: 20),
        );
        when(() => repository.fetchRemoteFontSetting('u1')).thenAnswer(
          (_) async =>
              const QuranFontSetting(fontFamily: 'Amiri', fontSize: 26),
        );
      },
      build: () => QuranFontSettingsCubit.test(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<QuranFontSettingsLoadedState>()
            .having((s) => s.fontFamily, 'fontFamily', 'Lateef'),
        isA<QuranFontSettingsLoadedState>()
            .having((s) => s.fontFamily, 'fontFamily', 'Amiri')
            .having((s) => s.fontSize, 'fontSize', 26),
      ],
    );
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}
