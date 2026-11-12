import 'package:dio/dio.dart';

import 'failures.dart';

class DioErrorMapper {
  DioErrorMapper._();

  static Failure map(Object error) {
    if (error is DioException) {
      if (error.response != null) {
        final response = error.response!;
        final statusCode = response.statusCode;
        final dynamic data = response.data;
        String? serverMessage;
        String? serverCode;

        if (data is Map<String, dynamic>) {
          serverMessage = data['message'] as String?;
          serverCode = data['code'] as String?;
        }

        if (statusCode == 401) {
          return AuthFailure(
            serverMessage ??
                'Session expired or invalid credentials. Please log in again.',
            code: serverCode ?? 'UNAUTHORIZED',
          );
        } else if (statusCode == 403) {
          return AuthFailure(
            serverMessage ?? 'Access denied. You do not have permission to perform this action.',
            code: serverCode ?? 'FORBIDDEN',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            serverMessage ??
                'Internal server error occurred. Please try again later.',
            code: serverCode ?? 'SERVER_ERROR',
          );
        }

        return ServerFailure(
          serverMessage ?? 'Unexpected response from server ($statusCode).',
          code: serverCode ?? 'BAD_RESPONSE',
        );
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const TimeoutFailure(
            'Connection timed out. Please try again.',
          );

        case DioExceptionType.connectionError:
          return const NetworkFailure(
            'No internet connection. Please verify your network.',
          );

        case DioExceptionType.cancel:
          return const ServerFailure(
            'Request was cancelled.',
            code: 'CANCELLED',
          );

        default:
          return ServerFailure(
            error.message ?? 'An unexpected network error occurred.',
            code: 'UNKNOWN_NETWORK_ERROR',
          );
      }
    }

    if (error is Failure) {
      return error;
    }

    return ServerFailure(
      'An unexpected error occurred: $error',
      code: 'UNEXPECTED_ERROR',
    );
  }
}
