import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../repositories/attendance_repository.dart';

/// Single-responsibility usecase to sync offline pending attendance records with the remote backend.
class SyncAttendanceUsecase {
  final AttendanceRepository repository;

  const SyncAttendanceUsecase(this.repository);

  Future<Result<Failure, int>> call() async {
    return await repository.syncPendingRecords();
  }
}

