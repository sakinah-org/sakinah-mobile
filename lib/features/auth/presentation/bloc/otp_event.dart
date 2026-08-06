abstract class OtpEvent {}

class VerifyOtpSubmittedEvent extends OtpEvent {
  final String code;

  VerifyOtpSubmittedEvent({required this.code});
}

class ResendOtpRequestedEvent extends OtpEvent {}

/// Internal — dispatched once a second by the countdown [Timer] to
/// recompute the remaining cooldown from real elapsed time.
class OtpCountdownTickedEvent extends OtpEvent {}
