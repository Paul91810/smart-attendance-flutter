import 'package:dio/dio.dart';
import 'app_config.dart';
import 'auth_interceptor.dart';
import 'mock_api_interceptor.dart';

class DioClient {
  final Dio dio;
  final AppConfig appConfig;
  final AuthInterceptor authInterceptor;
  final MockApiInterceptor? mockApiInterceptor;

  DioClient({
    required this.appConfig,
    required this.authInterceptor,
    this.mockApiInterceptor,
    Dio? dioInstance,
  }) : dio = dioInstance ?? Dio() {
    dio.options = BaseOptions(
      baseUrl: appConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    // 1. Interceptor for attaching auth token and catching 401
    dio.interceptors.add(authInterceptor);

    // 2. Mock API interceptor (simulates backend when useMock is true)
    if (appConfig.useMock) {
      dio.interceptors.add(mockApiInterceptor ?? MockApiInterceptor());
    }
  }

  // Convenience methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
}
