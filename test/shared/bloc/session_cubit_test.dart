import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_persistence_data_keys.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/models/user.dart';

/// Fakes just enough of path_provider for `Hive.initFlutter()` (used by
/// [SharedPrefHandler]) to work inside a plain `flutter_test` run, without
/// touching the real device filesystem.
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
        await Directory.systemTemp.createTemp('sakinah_session_cubit_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    // Real AppEnv/AESEncryptor/SharedPrefHandler, exactly as the app boots —
    // per project testing guidance, prefer real infra over mocks where the
    // classes are static singletons with no DI seam.
    await AppEnv.init('dev');
    AESEncryptor.init();
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await SharedPrefHandler.instance!.clear();
  });

  group('SessionCubit.restoreSession', () {
    test('empty box results in an unauthenticated state, no throw', () async {
      final cubit = SessionCubit.instance;

      await cubit.restoreSession();

      expect(cubit.isLoggedIn, isFalse);
      expect(cubit.currentUser, isNull);
    });

    test('valid encrypted entries restore an authenticated user', () async {
      final cubit = SessionCubit.instance;
      final user = User(id: 'u1', name: 'Test User', email: 'test@example.com');

      await cubit.persistSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        user: user,
      );
      await cubit.restoreSession();

      expect(cubit.isLoggedIn, isTrue);
      expect(cubit.currentUser?.id, 'u1');
      expect(cubit.currentUser?.name, 'Test User');
      expect(cubit.currentUser?.email, 'test@example.com');
    });

    test('corrupted token entry fails safe to unauthenticated', () async {
      final prefs = SharedPrefHandler.instance!;
      await prefs.save(AppPersistenceDataKeys.isLogin, value: true);
      await prefs.save(AppPersistenceDataKeys.accessToken,
          value: {'value': 'not-valid-ciphertext', 'iv': 'not-valid-iv'});
      await prefs.save(AppPersistenceDataKeys.refreshToken,
          value: {'value': 'not-valid-ciphertext', 'iv': 'not-valid-iv'});
      await prefs.save(AppPersistenceDataKeys.userData,
          value: {'id': 'x', 'name': 'x', 'email': 'x'});

      final cubit = SessionCubit.instance;

      await expectLater(cubit.restoreSession(), completes);
      expect(cubit.isLoggedIn, isFalse);
      expect(cubit.currentUser, isNull);
    });
  });

  group('SessionCubit.persistSession', () {
    test('writes all four Hive keys and tokens are not plain text', () async {
      final cubit = SessionCubit.instance;
      final user =
          User(id: 'u2', name: 'Another User', email: 'another@example.com');
      const plainAccessToken = 'super-secret-access-token';

      await cubit.persistSession(
        accessToken: plainAccessToken,
        refreshToken: 'super-secret-refresh-token',
        user: user,
      );

      final prefs = SharedPrefHandler.instance!;
      expect(prefs.get<bool>(key: AppPersistenceDataKeys.isLogin), isTrue);
      expect(prefs.contains(AppPersistenceDataKeys.accessToken), isTrue);
      expect(prefs.contains(AppPersistenceDataKeys.refreshToken), isTrue);
      expect(prefs.contains(AppPersistenceDataKeys.userData), isTrue);
      expect(cubit.isLoggedIn, isTrue);

      final storedAccessToken =
          prefs.get<Map>(key: AppPersistenceDataKeys.accessToken);
      expect(storedAccessToken['value'], isNot(equals(plainAccessToken)));
      expect(storedAccessToken['value'].toString(),
          isNot(contains(plainAccessToken)));
    });
  });
}
