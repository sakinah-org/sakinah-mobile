abstract class ResetPasswordEvent {}

class ResetPasswordSubmittedEvent extends ResetPasswordEvent {
  final String newPassword;
  final String confirmPassword;

  ResetPasswordSubmittedEvent({
    required this.newPassword,
    required this.confirmPassword,
  });
}
