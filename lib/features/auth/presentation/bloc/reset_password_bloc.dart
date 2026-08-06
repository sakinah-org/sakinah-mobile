import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'reset_password_event.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, AppStates>
    with Validations {
  ResetPasswordBloc(this._authRepository) : super(InitialState()) {
    on<ResetPasswordSubmittedEvent>(_onResetPasswordSubmitted);
  }

  final AuthRepository _authRepository;

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmittedEvent event,
    Emitter<AppStates> emit,
  ) async {
    final passwordError = isValidPassword(event.newPassword);
    if (passwordError.isNotEmpty) {
      emit(ErrorState(passwordError));
      return;
    }
    final confirmError =
        isValidConfirmPassword(event.newPassword, event.confirmPassword);
    if (confirmError.isNotEmpty) {
      emit(ErrorState(confirmError));
      return;
    }

    emit(LoadingState());
    try {
      await _authRepository.resetPassword(newPassword: event.newPassword);
      emit(SuccessState());
    } on Failure catch (failure) {
      emit(ErrorState(failure.message));
    } catch (_) {
      emit(ErrorState('Something went wrong. Please try again.'));
    }
  }
}
