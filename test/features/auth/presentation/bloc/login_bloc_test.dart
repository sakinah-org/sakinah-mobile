import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakinah/features/auth/presentation/bloc/login_bloc.dart';
import 'package:sakinah/features/auth/presentation/bloc/login_event.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/models/user.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);
  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;
}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockAuthRepository authRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sakinah_login_bloc_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    // SessionCubit.persistSession is a hard dependency of LoginBloc (no DI
    // seam, per the project's no-service-locator convention) — bootstrap the
    // real Hive/AESEncryptor infra it needs rather than mocking it away.
    await AppEnv.init('dev');
    AESEncryptor.init();
    await SharedPrefHandler.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    authRepository = MockAuthRepository();
    await SharedPrefHandler.instance!.clear();
  });

  final testUser =
      User(id: 'u1', name: 'Test User', email: 'valid@example.com');

  blocTest<LoginBloc, AppStates>(
    'emits [Loading, Loaded] and persists the session on valid credentials',
    setUp: () {
      when(() => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => (
            user: testUser,
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
          ));
    },
    build: () => LoginBloc(authRepository),
    act: (bloc) => bloc.add(
      LoginSubmittedEvent(email: 'valid@example.com', password: 'password123'),
    ),
    expect: () => [isA<LoadingState>(), isA<LoadedState>()],
    verify: (_) {
      expect(SessionCubit.instance.isLoggedIn, isTrue);
      expect(SessionCubit.instance.currentUser?.id, 'u1');
    },
  );

  blocTest<LoginBloc, AppStates>(
    'emits [Loading, Error] on wrong credentials, does not persist a session',
    setUp: () {
      when(() => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(UnauthorizedFailure('Invalid email or password'));
    },
    build: () => LoginBloc(authRepository),
    act: (bloc) => bloc.add(
      LoginSubmittedEvent(email: 'valid@example.com', password: 'wrongpass'),
    ),
    expect: () => [isA<LoadingState>(), isA<ErrorState>()],
    verify: (_) {
      expect(SessionCubit.instance.isLoggedIn, isFalse);
    },
  );

  blocTest<LoginBloc, AppStates>(
    'invalid email format emits Error without calling the repository',
    build: () => LoginBloc(authRepository),
    act: (bloc) => bloc.add(
      LoginSubmittedEvent(email: 'not-an-email', password: 'password123'),
    ),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  blocTest<LoginBloc, AppStates>(
    'empty password emits Error without calling the repository',
    build: () => LoginBloc(authRepository),
    act: (bloc) => bloc.add(
      LoginSubmittedEvent(email: 'valid@example.com', password: ''),
    ),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  blocTest<LoginBloc, AppStates>(
    'network failure emits [Loading, Error]',
    setUp: () {
      when(() => authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(ConnectionFailure('Failed due to internet connection'));
    },
    build: () => LoginBloc(authRepository),
    act: (bloc) => bloc.add(
      LoginSubmittedEvent(email: 'valid@example.com', password: 'password123'),
    ),
    expect: () => [isA<LoadingState>(), isA<ErrorState>()],
  );
}
