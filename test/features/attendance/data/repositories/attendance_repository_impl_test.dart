import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/network/network_info.dart';
import 'package:smart_attendance/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:smart_attendance/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:smart_attendance/features/attendance/data/models/attendance_record_model.dart';
import 'package:smart_attendance/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:smart_attendance/features/auth/data/models/user_model.dart';
import 'package:smart_attendance/features/auth/domain/entities/user_role.dart';

class MockRemoteDataSource extends Mock implements AttendanceRemoteDataSource {}
class MockLocalDataSource extends Mock implements AttendanceLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockAuthLocalDataSource mockAuthLocalDataSource;
  late AttendanceRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AttendanceRecordModel(
      id: 1,
      employeeId: 'EMP001',
      type: AttendanceType.checkIn,
      timestamp: DateTime.now(),
      latitude: 12.9716,
      longitude: 77.5946,
      sessionId: 'ses_1',
      synced: true,
    ));
    registerFallbackValue(AttendanceType.checkIn);
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockAuthLocalDataSource = MockAuthLocalDataSource();

    repository = AttendanceRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      authLocalDataSource: mockAuthLocalDataSource,
    );
  });

  final testRecordModel = AttendanceRecordModel(
    id: 10,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: DateTime(2026, 11, 12, 9, 30),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'ses_123',
    synced: true,
  );

  final testUser = const UserModel(
    id: 'emp_001',
    employeeId: 'EMP001',
    name: 'Alice Johnson',
    email: 'alice@smartattendance.com',
    role: UserRole.employee,
  );

  String generateValidPayload({
    required String sessionId,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required String nonce,
    bool tampered = false,
  }) {
    final issuedStr = issuedAt.toIso8601String();
    final expiresStr = expiresAt.toIso8601String();
    final message = '$sessionId:$issuedStr:$expiresStr:$nonce';
    final key = utf8.encode(AppConstants.hmacSecret);
    final hmacSha256 = Hmac(sha256, key);
    final signature = tampered
        ? 'invalid_signature_hex_123'
        : hmacSha256.convert(utf8.encode(message)).toString();

    return jsonEncode({
      'sessionId': sessionId,
      'issuedAt': issuedStr,
      'expiresAt': expiresStr,
      'nonce': nonce,
      'signature': signature,
    });
  }

  group('markAttendance - Online Path', () {
    test('calls remoteDataSource.scanAttendance and caches locally with synced=true when connected', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.scanAttendance(
            qrPayload: any(named: 'qrPayload'),
            type: any(named: 'type'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          )).thenAnswer((_) async => testRecordModel);
      when(() => mockLocalDataSource.insertRecord(any()))
          .thenAnswer((_) async => 1);

      final result = await repository.markAttendance(
        qrPayload: '{"sessionId":"ses_123"}',
        type: AttendanceType.checkIn,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(result.isSuccess, isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (record) {
          expect(record.employeeId, 'EMP001');
          expect(record.synced, isTrue);
        },
      );
      verify(() => mockRemoteDataSource.scanAttendance(
            qrPayload: any(named: 'qrPayload'),
            type: any(named: 'type'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          )).called(1);
      verify(() => mockLocalDataSource.insertRecord(any())).called(1);
    });
  });

  group('markAttendance - Offline Path', () {
    test('validates payload locally and inserts record with synced=false when disconnected', () async {
      final now = DateTime.now();
      final validPayload = generateValidPayload(
        sessionId: 'ses_offline_001',
        issuedAt: now.subtract(const Duration(seconds: 10)),
        expiresAt: now.add(const Duration(seconds: 50)),
        nonce: 'nonce_unique_offline_123',
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockAuthLocalDataSource.getCachedUser()).thenAnswer((_) async => testUser);
      when(() => mockLocalDataSource.getAttendanceHistory('EMP001'))
          .thenAnswer((_) async => []);
      when(() => mockLocalDataSource.insertRecord(any()))
          .thenAnswer((_) async => 42);

      final result = await repository.markAttendance(
        qrPayload: validPayload,
        type: AttendanceType.checkIn,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(result.isSuccess, isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (record) {
          expect(record.employeeId, 'EMP001');
          expect(record.synced, isFalse);
          expect(record.sessionId, 'ses_offline_001');
        },
      );
      verify(() => mockLocalDataSource.insertRecord(any(that: predicate<AttendanceRecordModel>((m) => !m.synced)))).called(1);
    });

    test('returns QrValidationFailure when offline and HMAC signature is tampered', () async {
      final now = DateTime.now();
      final tamperedPayload = generateValidPayload(
        sessionId: 'ses_offline_tampered',
        issuedAt: now.subtract(const Duration(seconds: 5)),
        expiresAt: now.add(const Duration(seconds: 55)),
        nonce: 'nonce_tampered_123',
        tampered: true,
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockAuthLocalDataSource.getCachedUser()).thenAnswer((_) async => testUser);

      final result = await repository.markAttendance(
        qrPayload: tamperedPayload,
        type: AttendanceType.checkIn,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(result.isFailure, isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<QrValidationFailure>());
          expect((failure as QrValidationFailure).code, 'INVALID_SIGNATURE');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('returns QrValidationFailure when offline and QR code is expired', () async {
      final now = DateTime.now();
      final expiredPayload = generateValidPayload(
        sessionId: 'ses_offline_expired',
        issuedAt: now.subtract(const Duration(seconds: 120)),
        expiresAt: now.subtract(const Duration(seconds: 60)),
        nonce: 'nonce_expired_123',
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockAuthLocalDataSource.getCachedUser()).thenAnswer((_) async => testUser);

      final result = await repository.markAttendance(
        qrPayload: expiredPayload,
        type: AttendanceType.checkIn,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(result.isFailure, isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<QrValidationFailure>());
          expect((failure as QrValidationFailure).code, 'QR_EXPIRED');
        },
        (_) => fail('Expected failure'),
      );
    });
  });

  group('syncPendingRecords', () {
    test('uploads each unsynced record to remote and updates local synced status to true', () async {
      final unsynced = [
        AttendanceRecordModel(
          id: 1,
          employeeId: 'EMP001',
          type: AttendanceType.checkIn,
          timestamp: DateTime(2026, 11, 12, 9, 0),
          latitude: 12.9716,
          longitude: 77.5946,
          sessionId: 'ses_pending_1',
          synced: false,
        ),
      ];

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getUnsyncedRecords())
          .thenAnswer((_) async => unsynced);
      when(() => mockRemoteDataSource.uploadOfflineRecord(any()))
          .thenAnswer((_) async => testRecordModel);
      when(() => mockLocalDataSource.markAsSynced(1))
          .thenAnswer((_) async {});

      final result = await repository.syncPendingRecords();

      expect(result.isSuccess, isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (count) => expect(count, 1),
      );
      verify(() => mockRemoteDataSource.uploadOfflineRecord(any())).called(1);
      verify(() => mockLocalDataSource.markAsSynced(1)).called(1);
    });
  });
}
