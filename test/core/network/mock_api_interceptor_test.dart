import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/network/mock_api_interceptor.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.smartattendance.local/v1'));
    // Latency 0 for fast unit tests
    dio.interceptors.add(MockApiInterceptor(latencyMs: 0));
  });

  group('MockApiInterceptor', () {
    test('POST /auth/login succeeds with valid admin credentials', () async {
      final response = await dio.post(
        '/auth/login',
        data: {
          'identifier': 'admin@smartattendance.com',
          'password': 'admin123',
        },
      );

      expect(response.statusCode, 200);
      expect(response.data['success'], isTrue);
      expect(response.data['data']['token'], startsWith('mock-jwt-usr_admin_000'));
      expect(response.data['data']['user']['role'], 'admin');
      expect(response.data['data']['user']['employeeId'], 'EMP000');
    });

    test('POST /auth/login succeeds with valid employee ID', () async {
      final response = await dio.post(
        '/auth/login',
        data: {
          'identifier': 'EMP001',
          'password': 'password123',
        },
      );

      expect(response.statusCode, 200);
      expect(response.data['success'], isTrue);
      expect(response.data['data']['user']['name'], 'Alice Johnson');
      expect(response.data['data']['user']['role'], 'employee');
    });

    test('POST /auth/login returns 401 with INVALID_CREDENTIALS for wrong password', () async {
      try {
        await dio.post(
          '/auth/login',
          data: {
            'identifier': 'admin@smartattendance.com',
            'password': 'wrongpassword',
          },
        );
        fail('Should throw DioException with 401');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
        expect(e.response?.data['success'], isFalse);
        expect(e.response?.data['code'], 'INVALID_CREDENTIALS');
      }
    });

    test('Unknown endpoint returns 404 with ROUTE_NOT_FOUND', () async {
      try {
        await dio.get('/unknown/route');
        fail('Should throw DioException with 404');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
        expect(e.response?.data['code'], 'ROUTE_NOT_FOUND');
      }
    });
  });
}
