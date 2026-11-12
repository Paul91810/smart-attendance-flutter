import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/features/attendance/domain/usecases/get_my_attendance_history_usecase.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/history/history_bloc.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/history/history_event.dart';
import 'package:smart_attendance/features/attendance/presentation/bloc/history/history_state.dart';

class MockGetMyAttendanceHistoryUsecase extends Mock
    implements GetMyAttendanceHistoryUsecase {}

void main() {
  late MockGetMyAttendanceHistoryUsecase mockUsecase;

  setUp(() {
    mockUsecase = MockGetMyAttendanceHistoryUsecase();
  });

  final now = DateTime.now();
  final todayRecord = AttendanceRecord(
    id: 1,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: now,
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-001',
    synced: true,
  );
  final yesterdayRecord = AttendanceRecord(
    id: 2,
    employeeId: 'EMP001',
    type: AttendanceType.checkIn,
    timestamp: now.subtract(const Duration(days: 1)),
    latitude: 12.9716,
    longitude: 77.5946,
    sessionId: 'SES-002',
    synced: true,
  );

  test('initial state is HistoryInitial', () {
    final bloc = HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    expect(bloc.state, equals(const HistoryInitial()));
    bloc.close();
  });

  blocTest<HistoryBloc, HistoryState>(
    'LoadHistory emits [HistoryLoading, HistoryLoaded] when records are returned',
    build: () {
      when(() => mockUsecase())
          .thenAnswer((_) async => Result.success([todayRecord, yesterdayRecord]));
      return HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    },
    act: (bloc) => bloc.add(const LoadHistory()),
    expect: () => [
      const HistoryLoading(),
      HistoryLoaded(records: [todayRecord, yesterdayRecord]),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'LoadHistory emits [HistoryLoading, HistoryEmpty] when empty list returned',
    build: () {
      when(() => mockUsecase()).thenAnswer((_) async => const Result.success([]));
      return HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    },
    act: (bloc) => bloc.add(const LoadHistory()),
    expect: () => [
      const HistoryLoading(),
      const HistoryEmpty(),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'LoadHistory emits [HistoryLoading, HistoryFailure] on failure',
    build: () {
      when(() => mockUsecase()).thenAnswer((_) async =>
          const Result.failure(ServerFailure('Failed to load', code: 'SERVER_ERR')));
      return HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    },
    act: (bloc) => bloc.add(const LoadHistory()),
    expect: () => [
      const HistoryLoading(),
      const HistoryFailure(message: 'Failed to load', code: 'SERVER_ERR'),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'HistoryFilterChanged filters records by selected date',
    build: () {
      when(() => mockUsecase())
          .thenAnswer((_) async => Result.success([todayRecord, yesterdayRecord]));
      return HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    },
    act: (bloc) async {
      bloc.add(const LoadHistory());
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(HistoryFilterChanged(date: now));
    },
    expect: () => [
      const HistoryLoading(),
      HistoryLoaded(records: [todayRecord, yesterdayRecord]),
      HistoryLoaded(records: [todayRecord], dateFilter: now),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'HistoryFilterChanged emits HistoryEmpty when no records match filter date',
    build: () {
      when(() => mockUsecase())
          .thenAnswer((_) async => Result.success([todayRecord]));
      return HistoryBloc(getMyAttendanceHistoryUsecase: mockUsecase);
    },
    act: (bloc) async {
      bloc.add(const LoadHistory());
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(HistoryFilterChanged(date: DateTime(2020, 1, 1)));
    },
    expect: () => [
      const HistoryLoading(),
      HistoryLoaded(records: [todayRecord]),
      HistoryEmpty(dateFilter: DateTime(2020, 1, 1)),
    ],
  );
}
