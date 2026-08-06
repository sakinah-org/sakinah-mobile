import 'package:sakinah/shared/models/user.dart';

/// # AuthRepository
/// ## Info
/// Single seam every auth screen Bloc depends on for Supabase Auth
/// operations. Implemented by [AuthRepositoryImpl]. All methods throw the
/// shared [Failure] hierarchy — never a raw Supabase `AuthException`.
abstract class AuthRepository {
  /// Signs in with email/password, then fetches the full user profile.
  /// Returns the composed [User] plus the session's access/refresh tokens.
  Future<({User user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });

  /// Creates a new account. Does not establish a session (no auto-login).
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Triggers a one-time recovery code email. Always succeeds from the
  /// caller's point of view unless a genuine transport/service failure
  /// occurs — never reveals whether [email] is actually registered.
  Future<void> requestPasswordRecovery({required String email});

  /// Verifies a recovery OTP, establishing a verified recovery session
  /// that [resetPassword] relies on.
  Future<void> verifyOtp({required String email, required String otp});

  /// Resends a fresh recovery OTP. Same underlying call as
  /// [requestPasswordRecovery], kept distinct for a clearly-named action.
  Future<void> resendOtp({required String email});

  /// Updates the password for the current verified recovery session.
  Future<void> resetPassword({required String newPassword});
}
