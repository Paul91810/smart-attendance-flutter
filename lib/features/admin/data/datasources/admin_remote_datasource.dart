import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_attendance_record_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/employee_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<EmployeeModel>> getEmployees();
  Future<List<AdminAttendanceRecordModel>> getAttendanceRecords({
    DateTime? date,
    String? employeeId,
  });
  Future<DashboardSummaryModel> getDashboardSummary();
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final DioClient dioClient;

  AdminRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await dioClient.get(ApiEndpoints.adminEmployees);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((item) => EmployeeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          message: err['message'] as String? ?? 'Failed to load employees',
          code: err['code'] as String?,
        );
      }
      throw ServerException(message: e.message ?? 'Employees request failed');
    } catch (e) {
      throw ServerException(message: 'Unexpected error loading employees: $e');
    }
  }

  @override
  Future<List<AdminAttendanceRecordModel>> getAttendanceRecords({
    DateTime? date,
    String? employeeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T').first;
      }
      if (employeeId != null && employeeId.isNotEmpty && employeeId != 'ALL') {
        queryParams['employeeId'] = employeeId;
      }

      final response = await dioClient.get(
        ApiEndpoints.adminAttendance,
        queryParameters: queryParams,
      );
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((item) =>
              AdminAttendanceRecordModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          message: err['message'] as String? ?? 'Failed to load attendance',
          code: err['code'] as String?,
        );
      }
      throw ServerException(message: e.message ?? 'Attendance request failed');
    } catch (e) {
      throw ServerException(message: 'Unexpected error loading attendance: $e');
    }
  }

  @override
  Future<DashboardSummaryModel> getDashboardSummary() async {
    try {
      final response = await dioClient.get(ApiEndpoints.adminSummary);
      final data = response.data['data'] as Map<String, dynamic>;
      return DashboardSummaryModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final err = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          message: err['message'] as String? ?? 'Failed to load summary',
          code: err['code'] as String?,
        );
      }
      throw ServerException(message: e.message ?? 'Summary request failed');
    } catch (e) {
      throw ServerException(message: 'Unexpected error loading summary: $e');
    }
  }
}
