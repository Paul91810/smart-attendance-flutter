/// Base and specific exceptions thrown by data sources.
class ServerException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, code: $code, message: $message)';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({required this.message, this.code});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => 'NetworkException($message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException($message)';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException($message)';
}

class QrValidationException implements Exception {
  final String message;
  final String? code;

  const QrValidationException({required this.message, this.code});

  @override
  String toString() => 'QrValidationException(code: $code, message: $message)';
}

class LocationException implements Exception {
  final String message;
  final String? code;

  const LocationException({required this.message, this.code});

  @override
  String toString() => 'LocationException(code: $code, message: $message)';
}
