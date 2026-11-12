import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../qr_session/domain/entities/qr_session.dart';
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
      return _markAttendanceOffline(
        qrPayload: qrPayload,
        type: type,
        latitude: latitude,
        longitude: longitude,
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

  @override
  Future<Result<Failure, List<AttendanceRecord>>> getUnsyncedRecords() async {
    try {
      final records = await localDataSource.getUnsyncedRecords();
      return Result.success(records);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to query unsynced records: $e'));
    }
  }

  @override
  Future<Result<Failure, int>> syncPendingRecords() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Result.failure(
        NetworkFailure('Cannot sync while offline. Please connect to the internet.'),
      );
    }

    try {
      final pendingRecords = await localDataSource.getUnsyncedRecords();
      if (pendingRecords.isEmpty) {
        return const Result.success(0);
      }

      int syncedCount = 0;
      for (final record in pendingRecords) {
        try {
          await remoteDataSource.uploadOfflineRecord(record);
          if (record.id != null) {
            await localDataSource.markAsSynced(record.id!);
          }
          syncedCount++;
        } catch (_) {
          // Keep failed record as unsynced so it can be retried later
        }
      }

      return Result.success(syncedCount);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Sync error: $e'));
    }
  }

  Future<Result<Failure, AttendanceRecord>> _markAttendanceOffline({
    required String qrPayload,
    required AttendanceType type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // 1. Parse JSON payload
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(qrPayload) as Map<String, dynamic>;
      } catch (_) {
        return const Result.failure(
          QrValidationFailure('Invalid QR code format.', code: 'INVALID_QR'),
        );
      }

      final sessionId = data['sessionId'] as String?;
      final issuedAtStr = data['issuedAt'] as String?;
      final expiresAtStr = data['expiresAt'] as String?;
      final nonce = data['nonce'] as String?;
      final signature = data['signature'] as String?;

      if (sessionId == null ||
          issuedAtStr == null ||
          expiresAtStr == null ||
          nonce == null ||
          signature == null) {
        return const Result.failure(
          QrValidationFailure('Malformed QR payload: missing required fields.',
              code: 'INVALID_QR'),
        );
      }

      final issuedAt = DateTime.parse(issuedAtStr);
      final expiresAt = DateTime.parse(expiresAtStr);

      final session = QrSession(
        sessionId: sessionId,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        nonce: nonce,
        signature: signature,
      );

      // 2. Validate HMAC signature locally
      final expectedSig = QrSession.computeHmacSignature(
        sessionId: sessionId,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        nonce: nonce,
        secret: AppConstants.hmacSecret,
      );
      if (expectedSig != signature) {
        return const Result.failure(
          QrValidationFailure(
            'Cryptographic signature verification failed. QR code may be tampered or counterfeit.',
            code: 'INVALID_SIGNATURE',
          ),
        );
      }

      // 3. Validate Expiry locally
      final now = DateTime.now();
      if (session.isExpiredAt(now)) {
        return const Result.failure(
          QrValidationFailure(
            'QR code session has expired. Please scan a fresh QR code.',
            code: 'QR_EXPIRED',
          ),
        );
      }

      // 4. Validate Authenticated Employee
      if (authLocalDataSource == null) {
        return const Result.failure(
          AuthFailure('Authentication credentials not found on device.',
              code: 'UNAUTHORIZED'),
        );
      }
      final cachedUser = await authLocalDataSource!.getCachedUser();
      if (cachedUser == null) {
        return const Result.failure(
          AuthFailure('No active user session. Please log in.',
              code: 'UNAUTHORIZED'),
        );
      }
      if (cachedUser.role != UserRole.employee) {
        return const Result.failure(
          AuthFailure('Only employees may scan attendance QR codes.',
              code: 'FORBIDDEN'),
        );
      }

      // 5. Query local records for today to validate duplicate attendance & check-out order
      final history =
          await localDataSource.getAttendanceHistory(cachedUser.employeeId);
      final todayRecords = history.where((r) =>
          r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day);

      if (type == AttendanceType.checkIn) {
        final hasCheckInToday =
            todayRecords.any((r) => r.type == AttendanceType.checkIn);
        if (hasCheckInToday) {
          return const Result.failure(
            QrValidationFailure(
              'Attendance check-in has already been recorded for today.',
              code: 'DUPLICATE_ATTENDANCE',
            ),
          );
        }
      } else {
        // type == AttendanceType.checkOut
        final hasCheckInToday =
            todayRecords.any((r) => r.type == AttendanceType.checkIn);
        if (!hasCheckInToday) {
          return const Result.failure(
            QrValidationFailure(
              'Cannot check out without a prior check-in record for today.',
              code: 'NO_CHECK_IN',
            ),
          );
        }
      }

      // 6. Save offline record to SQLite with synced = false
      final recordModel = AttendanceRecordModel(
        employeeId: cachedUser.employeeId,
        type: type,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        sessionId: sessionId,
        synced: false,
      );

      final insertedId = await localDataSource.insertRecord(recordModel);
      final savedRecord = AttendanceRecordModel(
        id: insertedId,
        employeeId: recordModel.employeeId,
        type: recordModel.type,
        timestamp: recordModel.timestamp,
        latitude: recordModel.latitude,
        longitude: recordModel.longitude,
        sessionId: recordModel.sessionId,
        synced: false,
      );

      return Result.success(savedRecord);
    } catch (e) {
      return Result.failure(
        CacheFailure('Failed to store attendance locally while offline: $e'),
      );
    }
  }
}
