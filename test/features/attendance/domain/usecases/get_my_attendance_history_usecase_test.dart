import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/get_my_attendance_history_usecase.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepository;
  late GetMyAttendanceHistoryUsecase usecase;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    usecase = GetMyAttendanceHistoryUsecase(mockRepository);
  });

  final testRecords = [
    AttendanceRecord(
      id: 1,
      employeeId: 'EMP001',
      type: AttendanceType.checkIn,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      latitude: 12.9716,
      longitude: 77.5946,
      sessionId: 'SES-001',
      synced: true,
    ),
    AttendanceRecord(
      id: 2,
      employeeId: 'EMP001',
      type: AttendanceType.checkOut,
      timestamp: DateTime.now(),
      latitude: 12.9716,
      longitude: 77.5946,
      sessionId: 'SES-002',
      synced: true,
    ),
  ];

  test('calls repository.getMyAttendanceHistory and returns records on success',
      () async {
    when(() => mockRepository.getMyAttendanceHistory())
        .thenAnswer((_) async => Result.success(testRecords));

    final result = await usecase();

    expect(result.isSuccess, isTrue);
    expect(result.data, equals(testRecords));
    verify(() => mockRepository.getMyAttendanceHistory()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns Failure when repository.getMyAttendanceHistory fails', () async {
    const failure = ServerFailure('Server error', code: 'SERVER_ERROR');
    when(() => mockRepository.getMyAttendanceHistory())
        .thenAnswer((_) async => const Result.failure(failure));

    final result = await usecase();

    expect(result.isFailure, isTrue);
    expect(result.error, equals(failure));
    verify(() => mockRepository.getMyAttendanceHistory()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
