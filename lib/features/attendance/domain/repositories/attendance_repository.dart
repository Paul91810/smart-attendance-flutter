import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<Result<Failure, AttendanceRecord>> markAttendance({
    required String qrPayload,
    required AttendanceType type,
    required double latitude,
    required double longitude,
  });

  Future<Result<Failure, List<AttendanceRecord>>> getAttendanceHistory({
    required String employeeId,
  });
}

