abstract class ForgotPasswordEvent {}

class SendOtpRequestedEvent extends ForgotPasswordEvent {
  final String email;

  SendOtpRequestedEvent({required this.email});
}
