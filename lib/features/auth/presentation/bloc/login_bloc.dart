import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'login_event.dart';

class LoginBloc extends Bloc<LoginEvent, AppStates> with Validations {
  LoginBloc(this._authRepository) : super(InitialState()) {
    on<LoginSubmittedEvent>(_onLoginSubmitted);
  }

  final AuthRepository _authRepository;

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AppStates> emit,
  ) async {
    final emailError = isValidEmail(event.email);
    if (emailError.isNotEmpty) {
      emit(ErrorState(emailError));
      return;
    }
    final passwordError = isValidPassword(event.password);
    if (passwordError.isNotEmpty) {
      emit(ErrorState(passwordError));
      return;
    }

    emit(LoadingState());
    try {
      final result = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      await SessionCubit.instance.persistSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      emit(LoadedState(result.user));
    } on Failure catch (failure) {
      emit(ErrorState(failure.message));
    } catch (_) {
      emit(ErrorState('Something went wrong. Please try again.'));
    }
  }
}
