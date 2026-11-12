import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/admin_attendance_record.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdminRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<Failure, List<Employee>>> getEmployees() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Result.failure(
        NetworkFailure('No network connection. Cannot retrieve employees.'),
      );
    }

    try {
      final employees = await remoteDataSource.getEmployees();
      return Result.success(employees);
    } on ServerException catch (e) {
      if (e.code == 'FORBIDDEN' || e.code == 'UNAUTHORIZED') {
        return Result.failure(AuthFailure(e.message, code: e.code));
      }
      return Result.failure(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to fetch employees: $e'));
    }
  }

  @override
  Future<Result<Failure, List<AdminAttendanceRecord>>> getAttendanceRecords({
    DateTime? date,
    String? employeeId,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Result.failure(
        NetworkFailure('No network connection. Cannot retrieve attendance records.'),
      );
    }

    try {
      final records = await remoteDataSource.getAttendanceRecords(
        date: date,
        employeeId: employeeId,
      );
      return Result.success(records);
    } on ServerException catch (e) {
      if (e.code == 'FORBIDDEN' || e.code == 'UNAUTHORIZED') {
        return Result.failure(AuthFailure(e.message, code: e.code));
      }
      return Result.failure(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to fetch attendance records: $e'));
    }
  }

  @override
  Future<Result<Failure, DashboardSummary>> getDashboardSummary() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Result.failure(
        NetworkFailure('No network connection. Cannot retrieve dashboard summary.'),
      );
    }

    try {
      final summary = await remoteDataSource.getDashboardSummary();
      return Result.success(summary);
    } on ServerException catch (e) {
      if (e.code == 'FORBIDDEN' || e.code == 'UNAUTHORIZED') {
        return Result.failure(AuthFailure(e.message, code: e.code));
      }
      return Result.failure(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to fetch dashboard summary: $e'));
    }
  }
}
