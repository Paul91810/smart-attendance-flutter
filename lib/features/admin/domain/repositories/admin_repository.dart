import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/admin_attendance_record.dart';
import '../entities/dashboard_summary.dart';
import '../entities/employee.dart';

abstract class AdminRepository {
  Future<Result<Failure, List<Employee>>> getEmployees();

  Future<Result<Failure, List<AdminAttendanceRecord>>> getAttendanceRecords({
    DateTime? date,
    String? employeeId,
  });

  Future<Result<Failure, DashboardSummary>> getDashboardSummary();
}
