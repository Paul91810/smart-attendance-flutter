import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/get_unsynced_records_usecase.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/sync_attendance_usecase.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/sync/sync_cubit.dart';

class MockSyncAttendanceUsecase extends Mock implements SyncAttendanceUsecase {}
class MockGetUnsyncedRecordsUsecase extends Mock implements GetUnsyncedRecordsUsecase {}

void main() {
  late MockSyncAttendanceUsecase mockSyncUsecase;
  late MockGetUnsyncedRecordsUsecase mockGetUnsyncedUsecase;

  setUp(() {
    mockSyncUsecase = MockSyncAttendanceUsecase();
    mockGetUnsyncedUsecase = MockGetUnsyncedRecordsUsecase();
  });

  final dummyRecord = AttendanceRecord(
    id: 1,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: DateTime.now(),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-001',
    synced: false,
  );

  group('SyncCubit', () {
    test('initial state is SyncIdle', () {
      when(() => mockGetUnsyncedUsecase())
          .thenAnswer((_) async => const Result.success([]));

      final cubit = SyncCubit(
        syncAttendanceUsecase: mockSyncUsecase,
        getUnsyncedRecordsUsecase: mockGetUnsyncedUsecase,
      );

      expect(cubit.state, const SyncIdle(pendingCount: 0));
    });

    blocTest<SyncCubit, SyncState>(
      'checkPendingCount emits SyncIdle with count of unsynced records',
      setUp: () {
        when(() => mockGetUnsyncedUsecase())
            .thenAnswer((_) async => Result.success([dummyRecord, dummyRecord]));
      },
      build: () => SyncCubit(
        syncAttendanceUsecase: mockSyncUsecase,
        getUnsyncedRecordsUsecase: mockGetUnsyncedUsecase,
      ),
      act: (cubit) => cubit.checkPendingCount(),
      expect: () => [
        const SyncIdle(pendingCount: 2),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'syncRecords emits [SyncInProgress, SyncSuccess] when pending records sync successfully',
      setUp: () {
        var records = [dummyRecord];
        when(() => mockGetUnsyncedUsecase())
            .thenAnswer((_) async => Result.success(records));
        when(() => mockSyncUsecase()).thenAnswer((_) async {
          records = [];
          return const Result.success(1);
        });
      },
      build: () => SyncCubit(
        syncAttendanceUsecase: mockSyncUsecase,
        getUnsyncedRecordsUsecase: mockGetUnsyncedUsecase,
      ),
      act: (cubit) => cubit.syncRecords(),
      expect: () => [
        const SyncIdle(pendingCount: 1),
        const SyncInProgress(pendingCount: 1),
        const SyncSuccess(syncedCount: 1, remainingPending: 0),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'syncRecords emits [SyncInProgress, SyncFailure] when sync usecase fails',
      setUp: () {
        when(() => mockGetUnsyncedUsecase())
            .thenAnswer((_) async => Result.success([dummyRecord]));
        when(() => mockSyncUsecase()).thenAnswer(
          (_) async => const Result.failure(NetworkFailure('Connection lost during sync')),
        );
      },
      build: () => SyncCubit(
        syncAttendanceUsecase: mockSyncUsecase,
        getUnsyncedRecordsUsecase: mockGetUnsyncedUsecase,
      ),
      act: (cubit) => cubit.syncRecords(),
      expect: () => [
        const SyncIdle(pendingCount: 1),
        const SyncInProgress(pendingCount: 1),
        const SyncFailure(message: 'Connection lost during sync', pendingCount: 1),
      ],
    );

    blocTest<SyncCubit, SyncState>(
      'syncRecords does nothing when 0 pending records',
      setUp: () {
        when(() => mockGetUnsyncedUsecase())
            .thenAnswer((_) async => const Result.success([]));
      },
      build: () => SyncCubit(
        syncAttendanceUsecase: mockSyncUsecase,
        getUnsyncedRecordsUsecase: mockGetUnsyncedUsecase,
      ),
      act: (cubit) => cubit.syncRecords(),
      expect: () => [
        const SyncIdle(pendingCount: 0),
      ],
    );
  });
}
