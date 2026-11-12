import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched upon application launch to verify existing session.
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Dispatched when the user submits the login form.
class LoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;

  const LoginSubmitted({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

/// Dispatched when the user requests logout.
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
