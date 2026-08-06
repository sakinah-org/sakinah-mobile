import 'package:sakinah/configurations/app_states.dart';

/// A single unified state for the OTP screen: unlike the other auth
/// screens, this one must represent a continuously-updating countdown
/// alongside submit status simultaneously, which the shared
/// Initial/Loading/Loaded/Error taxonomy cannot express cleanly — a
/// genuinely-warranted custom state class per Constitution Principle II.
class OtpState extends AppStates {
  final int secondsRemaining;
  final bool isVerifying;
  final bool isResending;
  final bool verified;
  final String? errorMessage;

  OtpState({
    this.secondsRemaining = 0,
    this.isVerifying = false,
    this.isResending = false,
    this.verified = false,
    this.errorMessage,
  });

  bool get canResend => secondsRemaining <= 0 && !isResending;

  OtpState copyWith({
    int? secondsRemaining,
    bool? isVerifying,
    bool? isResending,
    bool? verified,
    String? errorMessage,
  }) {
    return OtpState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      verified: verified ?? this.verified,
      errorMessage: errorMessage,
    );
  }
}
