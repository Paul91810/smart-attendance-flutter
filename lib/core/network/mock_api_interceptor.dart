import 'dart:async';
import 'package:dio/dio.dart';
import 'dummy_users.dart';

/// Interceptor that simulates a RESTful backend server with realistic network latency,
/// standard REST status codes, error handling, and in-memory mock user authentication.
class MockApiInterceptor extends Interceptor {
  final int latencyMs;

  MockApiInterceptor({this.latencyMs = 600});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Simulate network latency (600ms default)
    if (latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: latencyMs));
    }

    final path = options.path;
    final method = options.method.toUpperCase();

    try {
      // 2. Route matching
      if (path.endsWith('/auth/login') && method == 'POST') {
        return _handleLogin(options, handler);
      } else if (path.endsWith('/auth/logout') && method == 'POST') {
        return _handleLogout(options, handler);
      } else if (path.endsWith('/auth/me') && method == 'GET') {
        return _handleGetCurrentUser(options, handler);
      } else {
        // Default: 404 Not Found
        return respondNotFound(
          options,
          handler,
          code: 'ROUTE_NOT_FOUND',
          message: 'Endpoint not found: $method $path',
        );
      }
    } catch (e) {
      return respondServerError(
        options,
        handler,
        code: 'INTERNAL_ERROR',
        message: 'Mock server encountered an unexpected error: $e',
      );
    }
  }

  // ===================== Route Handlers =====================

  void _handleLogin(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    Map<String, dynamic> data;
    if (options.data is Map<String, dynamic>) {
      data = options.data as Map<String, dynamic>;
    } else if (options.data is FormData) {
      final formData = options.data as FormData;
      data = {
        for (final entry in formData.fields) entry.key: entry.value,
      };
    } else {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'BAD_REQUEST',
        message: 'Invalid request body payload format',
      );
    }

    final identifier = (data['identifier'] ?? data['email'] ?? data['employeeId'] ?? '')
        .toString()
        .trim();
    final password = (data['password'] ?? '').toString();

    if (identifier.isEmpty || password.isEmpty) {
      return respondError(
        options,
        handler,
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'Email/Employee ID and password are required',
      );
    }

    // Lookup user in in-memory dummy database
    final dummyUser = DummyUsersStore.findByIdentifier(identifier);
    if (dummyUser == null || dummyUser.password != password) {
      return respondUnauthorized(
        options,
        handler,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email/employee ID or password',
      );
    }

    // Success: return token + user profile
    final token = 'mock-jwt-${dummyUser.id}-${DateTime.now().millisecondsSinceEpoch}';
    return respondSuccess(
      options,
      handler,
      data: {
        'token': token,
        'user': dummyUser.toUserMap(),
      },
    );
  }

  void _handleLogout(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    return respondSuccess(
      options,
      handler,
      data: {'message': 'Logged out successfully'},
    );
  }

  void _handleGetCurrentUser(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final authHeader = options.headers['Authorization'] as String?;
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return respondUnauthorized(
        options,
        handler,
        code: 'UNAUTHORIZED',
        message: 'Missing or malformed Authorization header',
      );
    }

    final token = authHeader.substring(7);
    final parts = token.split('-');
    if (parts.length >= 3) {
      final userId = parts[2];
      final user = DummyUsersStore.findById(userId);
      if (user != null) {
        return respondSuccess(
          options,
          handler,
          data: user.toUserMap(),
        );
      }
    }

    final defaultUser = DummyUsersStore.users.first;
    return respondSuccess(
      options,
      handler,
      data: defaultUser.toUserMap(),
    );
  }

  // ===================== Standardized Response Helpers =====================

  void respondSuccess(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    required dynamic data,
    int statusCode = 200,
  }) {
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: statusCode,
        data: {
          'success': true,
          'data': data,
        },
      ),
    );
  }

  void respondError(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    required int statusCode,
    required String code,
    required String message,
  }) {
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: {
            'success': false,
            'code': code,
            'message': message,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  void respondUnauthorized(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'UNAUTHORIZED',
    String message = 'Authentication required or invalid credentials',
  }) {
    respondError(
      options,
      handler,
      statusCode: 401,
      code: code,
      message: message,
    );
  }

  void respondForbidden(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'FORBIDDEN',
    String message = 'You do not have permission to perform this action',
  }) {
    respondError(
      options,
      handler,
      statusCode: 403,
      code: code,
      message: message,
    );
  }

  void respondNotFound(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'NOT_FOUND',
    String message = 'The requested resource was not found',
  }) {
    respondError(
      options,
      handler,
      statusCode: 404,
      code: code,
      message: message,
    );
  }

  void respondServerError(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String code = 'SERVER_ERROR',
    String message = 'Internal server error occurred',
  }) {
    respondError(
      options,
      handler,
      statusCode: 500,
      code: code,
      message: message,
    );
  }

  void respondTimeout(
    RequestOptions options,
    RequestInterceptorHandler handler, {
    String message = 'Connection timed out',
  }) {
    handler.reject(
      DioException(
        requestOptions: options,
        message: message,
        type: DioExceptionType.connectionTimeout,
      ),
    );
  }
}
