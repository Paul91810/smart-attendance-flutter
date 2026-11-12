import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/sync_attendance_usecase.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepository;
  late SyncAttendanceUsecase usecase;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    usecase = SyncAttendanceUsecase(mockRepository);
  });

  test('calls repository.syncPendingRecords and returns synced count on success', () async {
    when(() => mockRepository.syncPendingRecords())
        .thenAnswer((_) async => const Result.success(3));

    final result = await usecase();

    expect(result.isSuccess, isTrue);
    result.fold(
      (_) => fail('Expected success'),
      (count) => expect(count, 3),
    );
    verify(() => mockRepository.syncPendingRecords()).called(1);
  });

  test('returns NetworkFailure when offline during sync', () async {
    when(() => mockRepository.syncPendingRecords()).thenAnswer(
      (_) async => const Result.failure(NetworkFailure('Cannot sync while offline.')),
    );

    final result = await usecase();

    expect(result.isFailure, isTrue);
    result.fold(
      (failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, contains('Cannot sync while offline'));
      },
      (_) => fail('Expected failure'),
    );
    verify(() => mockRepository.syncPendingRecords()).called(1);
  });
}
