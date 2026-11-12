import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final AttendanceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource? authLocalDataSource;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.authLocalDataSource,
  });

  @override
  Future<Result<Failure, AttendanceRecord>> markAttendance({
    required String qrPayload,
    required AttendanceType type,
    required double latitude,
    required double longitude,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Result.failure(
        NetworkFailure('No network connection. Cannot validate QR session.'),
      );
    }

    try {
      final remoteRecord = await remoteDataSource.scanAttendance(
        qrPayload: qrPayload,
        type: type,
        latitude: latitude,
        longitude: longitude,
      );

      // Persist to local SQLite for offline access & history
      try {
        final insertedId = await localDataSource.insertRecord(remoteRecord);
        final persistedRecord = AttendanceRecordModel(
          id: insertedId,
          employeeId: remoteRecord.employeeId,
          type: remoteRecord.type,
          timestamp: remoteRecord.timestamp,
          latitude: remoteRecord.latitude,
          longitude: remoteRecord.longitude,
          sessionId: remoteRecord.sessionId,
          synced: true,
        );
        return Result.success(persistedRecord);
      } catch (_) {
        // If local caching fails, the remote validation still succeeded
        return Result.success(remoteRecord);
      }
    } on ServerException catch (e) {
      final code = e.code;
      if (code == 'INVALID_SIGNATURE' ||
          code == 'QR_EXPIRED' ||
          code == 'QR_ALREADY_USED' ||
          code == 'DUPLICATE_ATTENDANCE' ||
          code == 'NO_CHECK_IN' ||
          code == 'INVALID_QR') {
        return Result.failure(QrValidationFailure(e.message, code: code));
      }
      if (code == 'FORBIDDEN' || code == 'UNAUTHORIZED') {
        return Result.failure(AuthFailure(e.message, code: code));
      }
      return Result.failure(ServerFailure(e.message, code: code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Unexpected scan failure: $e'));
    }
  }

  @override
  Future<Result<Failure, List<AttendanceRecord>>> getAttendanceHistory({
    required String employeeId,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteRecords = await remoteDataSource.getAttendanceHistory();
          return Result.success(remoteRecords);
        } catch (_) {
          // Fall back to local SQLite on remote error
        }
      }

      final localRecords = await localDataSource.getAttendanceHistory(employeeId);
      return Result.success(localRecords);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<Result<Failure, List<AttendanceRecord>>> getMyAttendanceHistory() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteRecords = await remoteDataSource.getMyAttendanceHistory();
          return Result.success(remoteRecords);
        } on ServerException catch (e) {
          if (e.code == 'UNAUTHORIZED') {
            return Result.failure(AuthFailure(e.message, code: e.code));
          }
          // On other server errors, try local cache fallback
        } catch (_) {
          // Fall back to local SQLite below
        }
      }

      if (authLocalDataSource != null) {
        final cachedUser = await authLocalDataSource!.getCachedUser();
        if (cachedUser != null) {
          final localRecords =
              await localDataSource.getAttendanceHistory(cachedUser.employeeId);
          return Result.success(localRecords);
        }
      }

      if (!isConnected) {
        return const Result.failure(
          NetworkFailure('No network connection and no cached records available.'),
        );
      }

      return const Result.success([]);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load personal history: $e'));
    }
  }
}
