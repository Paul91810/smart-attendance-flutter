import 'package:equatable/equatable.dart';

/// Base class for all failure representations in the domain layer.
/// Pure Dart, immutable and equatable.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Returned when a remote or mock server fails.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Returned when authentication or authorization fails.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Returned when no internet connectivity is detected.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
    String? code = 'NO_CONNECTION',
  ]) : super(code: code);
}

/// Returned when a network request times out.
class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'Connection timed out. Please try again.',
    String? code = 'TIMEOUT',
  ]) : super(code: code);
}

/// Returned when local caching / persistence fails.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Returned when client-side input validation fails.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Returned when a requested resource is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Returned when QR validation fails (signature, expiry, replay, etc.).
class QrValidationFailure extends Failure {
  const QrValidationFailure(super.message, {super.code});
}

/// Returned when device location capture fails (disabled, denied, etc.).
class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.code});
}
