import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/admin/domain/entities/admin_attendance_record.dart';
import 'package:smart_attendance/features/admin/domain/repositories/admin_repository.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_attendance_records_usecase.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late GetAttendanceRecordsUsecase usecase;

  setUp(() {
    mockRepository = MockAdminRepository();
    usecase = GetAttendanceRecordsUsecase(mockRepository);
  });

  final testDate = DateTime(2026, 11, 12);
  final testRecords = [
    AdminAttendanceRecord(
      id: 1,
      employeeId: 'EMP001',
      employeeName: 'John Doe',
      type: AttendanceType.checkIn,
      timestamp: testDate,
      latitude: 12.9716,
      longitude: 77.5946,
      sessionId: 'SES-001',
      synced: true,
    ),
  ];

  test('calls repository.getAttendanceRecords with filters and returns list',
      () async {
    when(() => mockRepository.getAttendanceRecords(
          date: testDate,
          employeeId: 'EMP001',
        )).thenAnswer((_) async => Result.success(testRecords));

    final result = await usecase(
      date: testDate,
      employeeId: 'EMP001',
    );

    expect(result.isSuccess, isTrue);
    expect(result.data, equals(testRecords));
    verify(() => mockRepository.getAttendanceRecords(
          date: testDate,
          employeeId: 'EMP001',
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns Failure when repository fails', () async {
    const failure = ServerFailure('Database query error');
    when(() => mockRepository.getAttendanceRecords(
          date: null,
          employeeId: null,
        )).thenAnswer((_) async => const Result.failure(failure));

    final result = await usecase();

    expect(result.isFailure, isTrue);
    expect(result.error, equals(failure));
  });
}
