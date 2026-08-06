import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakinah/features/auth/presentation/bloc/register_bloc.dart';
import 'package:sakinah/features/auth/presentation/bloc/register_event.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  blocTest<RegisterBloc, AppStates>(
    'emits [Loading, Success] on a valid new registration',
    setUp: () {
      when(() => authRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {});
    },
    build: () => RegisterBloc(authRepository),
    act: (bloc) => bloc.add(RegisterSubmittedEvent(
      name: 'Test User',
      email: 'new@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    )),
    expect: () => [isA<LoadingState>(), isA<SuccessState>()],
  );

  blocTest<RegisterBloc, AppStates>(
    'emits [Loading, Error] when the email is already registered',
    setUp: () {
      when(() => authRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(BadRequestFailure('Email already registered'));
    },
    build: () => RegisterBloc(authRepository),
    act: (bloc) => bloc.add(RegisterSubmittedEvent(
      name: 'Test User',
      email: 'existing@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    )),
    expect: () => [isA<LoadingState>(), isA<ErrorState>()],
  );

  blocTest<RegisterBloc, AppStates>(
    'mismatched confirmation emits Error without calling the repository',
    build: () => RegisterBloc(authRepository),
    act: (bloc) => bloc.add(RegisterSubmittedEvent(
      name: 'Test User',
      email: 'new@example.com',
      password: 'password123',
      confirmPassword: 'different456',
    )),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() => authRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  blocTest<RegisterBloc, AppStates>(
    'invalid name emits Error without calling the repository',
    build: () => RegisterBloc(authRepository),
    act: (bloc) => bloc.add(RegisterSubmittedEvent(
      name: 'A',
      email: 'new@example.com',
      password: 'password123',
      confirmPassword: 'password123',
    )),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() => authRepository.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );
}
