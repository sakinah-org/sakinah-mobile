import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakinah/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:sakinah/features/auth/presentation/bloc/forgot_password_event.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  blocTest<ForgotPasswordBloc, AppStates>(
    'emits [Loading, Loaded] and requests recovery for a registered email',
    setUp: () {
      when(() => authRepository.requestPasswordRecovery(
          email: any(named: 'email'))).thenAnswer((_) async {});
    },
    build: () => ForgotPasswordBloc(authRepository),
    act: (bloc) =>
        bloc.add(SendOtpRequestedEvent(email: 'registered@example.com')),
    expect: () => [isA<LoadingState>(), isA<LoadedState>()],
  );

  blocTest<ForgotPasswordBloc, AppStates>(
    'emits [Loading, Loaded] the same way for an unregistered email '
    '(never reveals account existence)',
    setUp: () {
      when(() => authRepository.requestPasswordRecovery(
          email: any(named: 'email'))).thenAnswer((_) async {});
    },
    build: () => ForgotPasswordBloc(authRepository),
    act: (bloc) =>
        bloc.add(SendOtpRequestedEvent(email: 'unregistered@example.com')),
    expect: () => [isA<LoadingState>(), isA<LoadedState>()],
  );

  blocTest<ForgotPasswordBloc, AppStates>(
    'invalid email emits Error without calling the repository',
    build: () => ForgotPasswordBloc(authRepository),
    act: (bloc) => bloc.add(SendOtpRequestedEvent(email: 'not-an-email')),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() =>
          authRepository.requestPasswordRecovery(email: any(named: 'email')));
    },
  );

  blocTest<ForgotPasswordBloc, AppStates>(
    'network failure emits [Loading, Error]',
    setUp: () {
      when(() => authRepository.requestPasswordRecovery(
              email: any(named: 'email')))
          .thenThrow(ConnectionFailure('Failed due to internet connection'));
    },
    build: () => ForgotPasswordBloc(authRepository),
    act: (bloc) =>
        bloc.add(SendOtpRequestedEvent(email: 'registered@example.com')),
    expect: () => [isA<LoadingState>(), isA<ErrorState>()],
  );
}
