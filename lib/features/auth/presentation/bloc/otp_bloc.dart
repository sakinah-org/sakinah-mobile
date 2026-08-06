import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'otp_event.dart';
import 'otp_state.dart';

const _resendCooldownSeconds = 60;

class OtpBloc extends Bloc<OtpEvent, OtpState> with Validations {
  OtpBloc(
    this._authRepository, {
    required this.email,
    DateTime Function()? clock,
  })  : _now = clock ?? DateTime.now,
        super(OtpState(secondsRemaining: _resendCooldownSeconds)) {
    on<VerifyOtpSubmittedEvent>(_onVerifyOtpSubmitted);
    on<ResendOtpRequestedEvent>(_onResendOtpRequested);
    on<OtpCountdownTickedEvent>(_onCountdownTicked);
    _startCountdown();
  }

  final AuthRepository _authRepository;
  final String email;

  /// Injectable so tests can simulate real elapsed time (including a
  /// backgrounding gap) without depending on wall-clock `DateTime.now()`.
  final DateTime Function() _now;

  Timer? _timer;
  late DateTime _resendAvailableAt =
      _now().add(const Duration(seconds: _resendCooldownSeconds));

  void _startCountdown() {
    _resendAvailableAt =
        _now().add(const Duration(seconds: _resendCooldownSeconds));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(OtpCountdownTickedEvent());
    });
  }

  void _onCountdownTicked(
      OtpCountdownTickedEvent event, Emitter<OtpState> emit) {
    // Recomputed from a stored end-time on every tick — reflects real
    // elapsed time even if the app was backgrounded mid-countdown, rather
    // than a naive decrementing counter.
    final remaining = _resendAvailableAt.difference(_now()).inSeconds;
    final clamped = remaining < 0 ? 0 : remaining;
    if (clamped == 0) {
      _timer?.cancel();
    }
    emit(state.copyWith(secondsRemaining: clamped));
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmittedEvent event,
    Emitter<OtpState> emit,
  ) async {
    final codeError = isValidCode(event.code);
    if (codeError.isNotEmpty) {
      emit(state.copyWith(errorMessage: codeError));
      return;
    }

    emit(state.copyWith(isVerifying: true, errorMessage: null));
    try {
      await _authRepository.verifyOtp(email: email, otp: event.code);
      // Stop the countdown once verified — otherwise it keeps ticking (and
      // re-emitting a still-`verified: true` state every second) for as
      // long as this Bloc stays alive, which it does even after navigating
      // away since pushing the next screen doesn't pop this one.
      _timer?.cancel();
      emit(state.copyWith(isVerifying: false, verified: true));
    } on Failure catch (failure) {
      emit(state.copyWith(isVerifying: false, errorMessage: failure.message));
    } catch (_) {
      emit(state.copyWith(
        isVerifying: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequestedEvent event,
    Emitter<OtpState> emit,
  ) async {
    if (!state.canResend) return;

    emit(state.copyWith(isResending: true, errorMessage: null));
    try {
      await _authRepository.resendOtp(email: email);
      _startCountdown();
      emit(state.copyWith(
        isResending: false,
        secondsRemaining: _resendCooldownSeconds,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(isResending: false, errorMessage: failure.message));
    } catch (_) {
      emit(state.copyWith(
        isResending: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
