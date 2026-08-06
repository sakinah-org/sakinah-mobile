import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'register_event.dart';

class RegisterBloc extends Bloc<RegisterEvent, AppStates> with Validations {
  RegisterBloc(this._authRepository) : super(InitialState()) {
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
  }

  final AuthRepository _authRepository;

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AppStates> emit,
  ) async {
    final nameError = isValidName(event.name);
    if (nameError.isNotEmpty) {
      emit(ErrorState(nameError));
      return;
    }
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
    final confirmPasswordError =
        isValidConfirmPassword(event.password, event.confirmPassword);
    if (confirmPasswordError.isNotEmpty) {
      emit(ErrorState(confirmPasswordError));
      return;
    }

    emit(LoadingState());
    try {
      await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(SuccessState());
    } on Failure catch (failure) {
      emit(ErrorState(failure.message));
    } catch (_) {
      emit(ErrorState('Something went wrong. Please try again.'));
    }
  }
}
