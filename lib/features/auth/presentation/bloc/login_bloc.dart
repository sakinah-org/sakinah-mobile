import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/handlers/fcm_handler.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/devices/data/repositories/user_device_repository_impl.dart';
import 'package:sakinah/shared/devices/domain/repositories/user_device_repository.dart';
import 'package:sakinah/toolkit/validations.dart';

import '../../domain/repositories/auth_repository.dart';
import 'login_event.dart';

class LoginBloc extends Bloc<LoginEvent, AppStates> with Validations {
  LoginBloc(this._authRepository, {UserDeviceRepository? deviceRepository})
      : _deviceRepository = deviceRepository ?? UserDeviceRepositoryImpl(),
        super(InitialState()) {
    on<LoginSubmittedEvent>(_onLoginSubmitted);
  }

  final AuthRepository _authRepository;
  final UserDeviceRepository _deviceRepository;

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
      unawaited(_registerDevice(result.user.id));
      emit(LoadedState(result.user));
    } on Failure catch (failure) {
      emit(ErrorState(failure.message));
    } catch (_) {
      emit(ErrorState('Something went wrong. Please try again.'));
    }
  }

  /// Best-effort FCM device registration right after login (specs
  /// 007-update-login-FCM). Never blocks the login UX and never fails it —
  /// both the token fetch and the upsert already swallow their own errors.
  Future<void> _registerDevice(String? userId) async {
    if (userId == null) return;
    final platform = FcmHandler.instance.platform;
    if (platform == null) return;
    final token = await FcmHandler.instance.getToken();
    if (token == null) return;
    await _deviceRepository.registerDevice(
      userId: userId,
      fcmToken: token,
      platform: platform,
    );
  }
}
