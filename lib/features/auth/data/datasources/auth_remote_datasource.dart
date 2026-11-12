import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final payload = data['data'] as Map<String, dynamic>;
        return LoginResponseModel.fromJson(payload);
      } else {
        throw ServerException(
          message: data is Map<String, dynamic>
              ? (data['message'] as String? ?? 'Login failed')
              : 'Unknown response format',
          code: data is Map<String, dynamic> ? data['code'] as String? : null,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Connection timeout or network failure. Please check your internet.');
      }

      final res = e.response;
      if (res?.statusCode == 401) {
        final msg = res?.data is Map<String, dynamic>
            ? (res!.data['message'] as String? ?? 'Invalid email/employee ID or password')
            : 'Invalid email/employee ID or password';
        final code = res?.data is Map<String, dynamic>
            ? res!.data['code'] as String?
            : 'INVALID_CREDENTIALS';
        throw AuthException(message: msg, code: code);
      }

      final errorMsg = res?.data is Map<String, dynamic>
          ? (res!.data['message'] as String? ?? 'Server error')
          : 'Server error: ${res?.statusCode}';
      throw ServerException(
        message: errorMsg,
        code: res?.data is Map<String, dynamic> ? res!.data['code'] as String? : null,
        statusCode: res?.statusCode,
      );
    } catch (e) {
      if (e is AuthException || e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Unexpected login error: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort remote notification for logout
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.get(ApiEndpoints.currentUser);
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const ServerException(message: 'Failed to fetch current user profile');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthException(message: 'Session expired', code: 'SESSION_EXPIRED');
      }
      throw ServerException(message: 'Failed to fetch user: ${e.message}');
    }
  }
}
