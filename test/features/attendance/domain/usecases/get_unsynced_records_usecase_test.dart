import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/get_unsynced_records_usecase.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepository;
  late GetUnsyncedRecordsUsecase usecase;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    usecase = GetUnsyncedRecordsUsecase(mockRepository);
  });

  final testRecord = AttendanceRecord(
    id: 1,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: DateTime.now(),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-001',
    synced: false,
  );

  test('calls repository.getUnsyncedRecords and returns list on success', () async {
    when(() => mockRepository.getUnsyncedRecords())
        .thenAnswer((_) async => Result.success([testRecord]));

    final result = await usecase();

    expect(result.isSuccess, isTrue);
    result.fold(
      (_) => fail('Expected success'),
      (records) {
        expect(records.length, 1);
        expect(records.first.synced, isFalse);
      },
    );
    verify(() => mockRepository.getUnsyncedRecords()).called(1);
  });

  test('returns CacheFailure when querying unsynced records fails', () async {
    when(() => mockRepository.getUnsyncedRecords()).thenAnswer(
      (_) async => const Result.failure(CacheFailure('Database read error')),
    );

    final result = await usecase();

    expect(result.isFailure, isTrue);
    result.fold(
      (failure) => expect(failure, isA<CacheFailure>()),
      (_) => fail('Expected failure'),
    );
  });
}

