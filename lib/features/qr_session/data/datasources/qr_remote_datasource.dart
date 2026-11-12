import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/qr_session_model.dart';

abstract class QrRemoteDataSource {
  Future<QrSessionModel> generateSession();
}

class QrRemoteDataSourceImpl implements QrRemoteDataSource {
  final DioClient dioClient;

  QrRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<QrSessionModel> generateSession() async {
    try {
      final response = await dioClient.post(ApiEndpoints.qrGenerate);
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final payload = data['data'] as Map<String, dynamic>;
        return QrSessionModel.fromJson(payload);
      } else {
        throw ServerException(
          message: data is Map<String, dynamic>
              ? (data['message'] as String? ?? 'Failed to generate QR session')
              : 'Invalid response format',
          code: data is Map<String, dynamic> ? data['code'] as String? : null,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Network error while generating QR code');
      }

      final res = e.response;
      final errorMsg = res?.data is Map<String, dynamic>
          ? (res!.data['message'] as String? ?? 'QR generation failed')
          : 'Failed to generate QR code: ${res?.statusCode}';
      final code = res?.data is Map<String, dynamic>
          ? res!.data['code'] as String?
          : null;

      if (res?.statusCode == 401) {
        throw AuthException(message: errorMsg, code: code ?? 'UNAUTHORIZED');
      } else if (res?.statusCode == 403) {
        throw AuthException(message: errorMsg, code: code ?? 'FORBIDDEN');
      }

      throw ServerException(
        message: errorMsg,
        code: code,
        statusCode: res?.statusCode,
      );
    } catch (e) {
      if (e is AuthException || e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Unexpected QR generation error: $e');
    }
  }
}
