import 'package:dio/dio.dart';

/// Interceptor that attaches JWT Bearer token to outgoing requests and handles 401 logout.
class AuthInterceptor extends QueuedInterceptor {
  final Future<String?> Function() getToken;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required this.getToken,
    this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If authorization header is not explicitly set, fetch token and attach
    if (!options.headers.containsKey('Authorization')) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
