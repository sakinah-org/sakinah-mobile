abstract class RegisterEvent {}

class RegisterSubmittedEvent extends RegisterEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  RegisterSubmittedEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}
