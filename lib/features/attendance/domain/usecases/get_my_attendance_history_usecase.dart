import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// Usecase for retrieving the authenticated employee's attendance records.
class GetMyAttendanceHistoryUsecase {
  final AttendanceRepository repository;

  GetMyAttendanceHistoryUsecase(this.repository);

  Future<Result<Failure, List<AttendanceRecord>>> call() async {
    return await repository.getMyAttendanceHistory();
  }
}
