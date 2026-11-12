import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
    String? code = 'NO_CONNECTION',
  ]) : super(code: code);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'Connection timed out. Please try again.',
    String? code = 'TIMEOUT',
  ]) : super(code: code);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

class QrValidationFailure extends Failure {
  const QrValidationFailure(super.message, {super.code});
}

class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.code});
}
