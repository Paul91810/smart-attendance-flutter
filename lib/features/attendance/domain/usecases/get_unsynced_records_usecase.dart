import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetUnsyncedRecordsUsecase {
  final AttendanceRepository repository;

  const GetUnsyncedRecordsUsecase(this.repository);

  Future<Result<Failure, List<AttendanceRecord>>> call() async {
    return await repository.getUnsyncedRecords();
  }
}

