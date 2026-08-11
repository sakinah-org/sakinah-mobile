import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_persistence_data_keys.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/bloc/settings_cubit.dart';

/// Fakes just enough of path_provider for `Hive.initFlutter()` (used by
/// [SharedPrefHandler]) to work inside a plain `flutter_test` run, without
/// touching the real device filesystem. Mirrors
/// test/shared/bloc/session_cubit_test.dart's approach: real
/// `SharedPrefHandler` over a temp Hive box rather than a mock, since it is
/// a static singleton with no DI seam (per project testing guidance).
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('sakinah_settings_cubit_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
    SettingsCubit.instance.locale = const Locale('ar');
  });

  group('SettingsCubit.setLocale', () {
    test('updates locale, persists it, and emits', () async {
      final cubit = SettingsCubit.instance;

      await cubit.setLocale(const Locale('en'));

      expect(cubit.locale.languageCode, 'en');
      expect(
        SharedPrefHandler.instance!
            .get<String>(key: AppPersistenceDataKeys.appLocale),
        'en',
      );
    });

    test('re-selecting the already-active language is a no-op value-wise',
        () async {
      final cubit = SettingsCubit.instance;
      await cubit.setLocale(const Locale('ar'));

      await cubit.setLocale(const Locale('ar'));

      expect(cubit.locale.languageCode, 'ar');
      expect(
        SharedPrefHandler.instance!
            .get<String>(key: AppPersistenceDataKeys.appLocale),
        'ar',
      );
    });
  });

  group('SettingsCubit.loadPersistedSettings', () {
    test('hydrates locale from a previously persisted value', () async {
      await SharedPrefHandler.instance!
          .save(AppPersistenceDataKeys.appLocale, value: 'en');
      final cubit = SettingsCubit.instance;
      cubit.locale = const Locale('ar');

      await cubit.loadPersistedSettings();

      expect(cubit.locale.languageCode, 'en');
    });

    test('falls back to the current default when nothing is persisted',
        () async {
      final cubit = SettingsCubit.instance;
      cubit.locale = const Locale('ar');

      await cubit.loadPersistedSettings();

      expect(cubit.locale.languageCode, 'ar');
    });
  });
}
