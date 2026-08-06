import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakinah/features/auth/presentation/bloc/reset_password_bloc.dart';
import 'package:sakinah/features/auth/presentation/bloc/reset_password_event.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  blocTest<ResetPasswordBloc, AppStates>(
    'emits [Loading, Success] on a valid new password',
    setUp: () {
      when(() => authRepository.resetPassword(
          newPassword: any(named: 'newPassword'))).thenAnswer((_) async {});
    },
    build: () => ResetPasswordBloc(authRepository),
    act: (bloc) => bloc.add(ResetPasswordSubmittedEvent(
      newPassword: 'newPassword123',
      confirmPassword: 'newPassword123',
    )),
    expect: () => [isA<LoadingState>(), isA<SuccessState>()],
  );

  blocTest<ResetPasswordBloc, AppStates>(
    'mismatched confirmation emits Error without calling the repository',
    build: () => ResetPasswordBloc(authRepository),
    act: (bloc) => bloc.add(ResetPasswordSubmittedEvent(
      newPassword: 'newPassword123',
      confirmPassword: 'different456',
    )),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() =>
          authRepository.resetPassword(newPassword: any(named: 'newPassword')));
    },
  );

  blocTest<ResetPasswordBloc, AppStates>(
    'weak password emits Error without calling the repository',
    build: () => ResetPasswordBloc(authRepository),
    act: (bloc) => bloc.add(ResetPasswordSubmittedEvent(
      newPassword: 'short',
      confirmPassword: 'short',
    )),
    expect: () => [isA<ErrorState>()],
    verify: (_) {
      verifyNever(() =>
          authRepository.resetPassword(newPassword: any(named: 'newPassword')));
    },
  );

  blocTest<ResetPasswordBloc, AppStates>(
    'network failure emits [Loading, Error]',
    setUp: () {
      when(() => authRepository.resetPassword(
              newPassword: any(named: 'newPassword')))
          .thenThrow(ConnectionFailure('Failed due to internet connection'));
    },
    build: () => ResetPasswordBloc(authRepository),
    act: (bloc) => bloc.add(ResetPasswordSubmittedEvent(
      newPassword: 'newPassword123',
      confirmPassword: 'newPassword123',
    )),
    expect: () => [isA<LoadingState>(), isA<ErrorState>()],
  );
}
