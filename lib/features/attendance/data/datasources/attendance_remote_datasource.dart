import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/attendance_record.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceRecordModel> scanAttendance({
    required String qrPayload,
    required AttendanceType type,
    required double latitude,
    required double longitude,
  });

  Future<List<AttendanceRecordModel>> getAttendanceHistory();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final DioClient dioClient;

  AttendanceRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AttendanceRecordModel> scanAttendance({
    required String qrPayload,
    required AttendanceType type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.attendanceScan,
        data: {
          'qrPayload': qrPayload,
          'type': type.toTypeString(),
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AttendanceRecordModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        final code = errData['code'] as String?;
        final message =
            errData['message'] as String? ?? 'Failed to validate attendance';
        throw ServerException(message: message, code: code);
      }
      throw ServerException(message: e.message ?? 'Attendance scan request failed');
    } catch (e) {
      throw ServerException(message: 'Unexpected error during attendance scan: $e');
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceHistory() async {
    try {
      final response = await dioClient.get(ApiEndpoints.attendanceHistory);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((item) =>
              AttendanceRecordModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final errData = e.response!.data as Map<String, dynamic>;
        throw ServerException(
          message: errData['message'] as String? ??
              'Failed to retrieve attendance history',
          code: errData['code'] as String?,
        );
      }
      throw ServerException(
          message: e.message ?? 'Attendance history request failed');
    } catch (e) {
      throw ServerException(
          message: 'Unexpected error fetching attendance history: $e');
    }
  }
}
