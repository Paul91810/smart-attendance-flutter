import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../repositories/attendance_repository.dart';

class SyncAttendanceUsecase {
  final AttendanceRepository repository;

  const SyncAttendanceUsecase(this.repository);

  Future<Result<Failure, int>> call() async {
    return await repository.syncPendingRecords();
  }
}

