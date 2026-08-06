import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'forgot_password_event.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, AppStates>
    with Validations {
  ForgotPasswordBloc(this._authRepository) : super(InitialState()) {
    on<SendOtpRequestedEvent>(_onSendOtpRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onSendOtpRequested(
    SendOtpRequestedEvent event,
    Emitter<AppStates> emit,
  ) async {
    final emailError = isValidEmail(event.email);
    if (emailError.isNotEmpty) {
      emit(ErrorState(emailError));
      return;
    }

    emit(LoadingState());
    try {
      await _authRepository.requestPasswordRecovery(email: event.email);
      // Supabase's /recover endpoint always succeeds regardless of whether
      // the email is registered — the UI must not use this outcome to
      // reveal account existence either way.
      emit(LoadedState(event.email));
    } on Failure catch (failure) {
      emit(ErrorState(failure.message));
    } catch (_) {
      emit(ErrorState('Something went wrong. Please try again.'));
    }
  }
}
