import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/admin_attendance_record.dart';
import '../repositories/admin_repository.dart';

class GetAttendanceRecordsUsecase {
  final AdminRepository repository;

  GetAttendanceRecordsUsecase(this.repository);

  Future<Result<Failure, List<AdminAttendanceRecord>>> call({
    DateTime? date,
    String? employeeId,
  }) async {
    return await repository.getAttendanceRecords(
      date: date,
      employeeId: employeeId,
    );
  }
}
