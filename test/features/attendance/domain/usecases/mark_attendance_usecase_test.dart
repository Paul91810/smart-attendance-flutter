import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/mark_attendance_usecase.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepository;
  late MarkAttendanceUsecase usecase;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    usecase = MarkAttendanceUsecase(mockRepository);
  });

  final testRecord = AttendanceRecord(
    id: 1,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: DateTime.now(),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-001',
    synced: true,
  );

  test('returns QrValidationFailure without calling repository when payload is empty', () async {
    const params = MarkAttendanceParams(
      qrPayload: '   ',
      type: AttendanceType.checkIn,
      latitude: 12.9716,
      longitude: 77.5946,
    );

    final result = await usecase(params);

    expect(result.isFailure, isTrue);
    result.fold(
      (failure) {
        expect(failure, isA<QrValidationFailure>());
        expect(failure.code, 'INVALID_QR');
      },
      (_) => fail('Expected failure'),
    );
    verifyZeroInteractions(mockRepository);
  });

  test('calls repository.markAttendance and returns AttendanceRecord on success', () async {
    const params = MarkAttendanceParams(
      qrPayload: '{"sessionId":"SES-001"}',
      type: AttendanceType.checkIn,
      latitude: 12.9716,
      longitude: 77.5946,
    );

    when(() => mockRepository.markAttendance(
          qrPayload: params.qrPayload,
          type: params.type,
          latitude: params.latitude,
          longitude: params.longitude,
        )).thenAnswer((_) async => Result.success(testRecord));

    final result = await usecase(params);

    expect(result.isSuccess, isTrue);
    result.fold(
      (_) => fail('Expected success'),
      (record) {
        expect(record, equals(testRecord));
      },
    );
    verify(() => mockRepository.markAttendance(
          qrPayload: params.qrPayload,
          type: params.type,
          latitude: params.latitude,
          longitude: params.longitude,
        )).called(1);
  });

  test('returns Failure when repository.markAttendance fails', () async {
    const params = MarkAttendanceParams(
      qrPayload: '{"sessionId":"SES-001"}',
      type: AttendanceType.checkIn,
      latitude: 12.9716,
      longitude: 77.5946,
    );

    const failure = QrValidationFailure('QR has expired', code: 'QR_EXPIRED');

    when(() => mockRepository.markAttendance(
          qrPayload: params.qrPayload,
          type: params.type,
          latitude: params.latitude,
          longitude: params.longitude,
        )).thenAnswer((_) async => const Result.failure(failure));

    final result = await usecase(params);

    expect(result.isFailure, isTrue);
    result.fold(
      (f) => expect(f.code, 'QR_EXPIRED'),
      (_) => fail('Expected failure'),
    );
    verify(() => mockRepository.markAttendance(
          qrPayload: params.qrPayload,
          type: params.type,
          latitude: params.latitude,
          longitude: params.longitude,
        )).called(1);
  });
}

