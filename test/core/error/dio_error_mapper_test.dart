import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/error/dio_error_mapper.dart';
import 'package:smart_attendance/core/error/failures.dart';

void main() {
  group('DioErrorMapper', () {
    final reqOptions = RequestOptions(path: '/test');

    test('maps connectionTimeout to TimeoutFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<TimeoutFailure>());
      expect(failure.code, 'TIMEOUT');
    });

    test('maps sendTimeout to TimeoutFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.sendTimeout,
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<TimeoutFailure>());
    });

    test('maps receiveTimeout to TimeoutFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.receiveTimeout,
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<TimeoutFailure>());
    });

    test('maps connectionError to NetworkFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<NetworkFailure>());
      expect(failure.code, 'NO_CONNECTION');
    });

    test('maps 401 response with code and message to AuthFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 401,
          data: {
            'code': 'TOKEN_EXPIRED',
            'message': 'Your session has expired',
          },
        ),
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Your session has expired');
      expect(failure.code, 'TOKEN_EXPIRED');
    });

    test('maps 403 response to AuthFailure FORBIDDEN', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 403,
          data: {'message': 'Permission denied'},
        ),
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, 'FORBIDDEN');
    });

    test('maps 500 response to ServerFailure', () {
      final dioException = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 500,
          data: {'message': 'Internal database error', 'code': 'DB_ERR'},
        ),
      );

      final failure = DioErrorMapper.map(dioException);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Internal database error');
      expect(failure.code, 'DB_ERR');
    });

    test('maps generic unknown exception to ServerFailure', () {
      final failure = DioErrorMapper.map(Exception('Socket closed unexpectedly'));

      expect(failure, isA<ServerFailure>());
      expect(failure.message, contains('Socket closed unexpectedly'));
    });
  });
}
