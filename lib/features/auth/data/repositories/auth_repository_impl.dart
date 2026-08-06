import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/shared/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  supabase.GoTrueClient get _auth => supabase.Supabase.instance.client.auth;

  User _userFromSupabase(supabase.User supabaseUser) {
    return User(
      id: supabaseUser.id,
      name: supabaseUser.userMetadata?['name'] as String?,
      email: supabaseUser.email,
    );
  }

  @override
  Future<({User user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      final supabaseUser = response.user;
      if (session == null || supabaseUser == null) {
        throw UnauthorizedFailure("Invalid email or password");
      }
      // Step 2: user data for the signed-in id is already embedded in the
      // sign-in response (no separate profiles table in this project yet).
      return (
        user: _userFromSupabase(supabaseUser),
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );
    } on supabase.AuthException catch (e) {
      throw Failure.handleAuthException(e);
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
    } on supabase.AuthException catch (e) {
      throw Failure.handleAuthException(e);
    }
  }

  @override
  Future<void> requestPasswordRecovery({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw Failure.handleAuthException(e);
    }
  }

  @override
  Future<void> resendOtp({required String email}) =>
      requestPasswordRecovery(email: email);

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      await _auth.verifyOTP(
        email: email,
        token: otp,
        type: supabase.OtpType.recovery,
      );
    } on supabase.AuthException catch (e) {
      throw Failure.handleAuthException(e);
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    try {
      await _auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      throw Failure.handleAuthException(e);
    }
  }
}
