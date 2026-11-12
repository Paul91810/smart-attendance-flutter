import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before session validation begins.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Emitted while performing auth checks or submitting credentials.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Emitted when the user is successfully authenticated.
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Emitted when no valid session is present or user has logged out.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Emitted when login or session verification fails with an error message.
class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
