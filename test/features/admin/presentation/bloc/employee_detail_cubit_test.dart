import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/admin/domain/entities/admin_attendance_record.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_attendance_records_usecase.dart';
import 'package:smart_attendance/features/admin/presentation/bloc/employee_detail/employee_detail_cubit.dart';
import 'package:smart_attendance/features/admin/presentation/bloc/employee_detail/employee_detail_state.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';

class MockGetAttendanceRecordsUsecase extends Mock
    implements GetAttendanceRecordsUsecase {}

void main() {
  late MockGetAttendanceRecordsUsecase mockUsecase;
  late EmployeeDetailCubit cubit;

  setUp(() {
    mockUsecase = MockGetAttendanceRecordsUsecase();
    cubit = EmployeeDetailCubit(getAttendanceRecordsUsecase: mockUsecase);
  });

  final testRecords = [
    AdminAttendanceRecord(
      id: 1,
      employeeId: 'EMP001',
      employeeName: 'Alice Johnson',
      type: AttendanceType.checkIn,
      timestamp: DateTime(2026, 11, 12, 9, 0),
      latitude: 12.9716,
      longitude: 77.5946,
      sessionId: 'ses_1',
      synced: true,
    ),
  ];

  test('initial state is EmployeeDetailInitial', () {
    expect(cubit.state, const EmployeeDetailInitial());
  });

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    'emits [EmployeeDetailLoading, EmployeeDetailLoaded] on successful fetch',
    build: () {
      when(() => mockUsecase(employeeId: 'EMP001'))
          .thenAnswer((_) async => Result.success(testRecords));
      return cubit;
    },
    act: (cubit) => cubit.loadEmployeeRecords('EMP001'),
    expect: () => [
      const EmployeeDetailLoading(),
      EmployeeDetailLoaded(testRecords),
    ],
  );

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    'emits [EmployeeDetailLoading, EmployeeDetailError] on failure',
    build: () {
      when(() => mockUsecase(employeeId: 'EMP001'))
          .thenAnswer((_) async => const Result.failure(ServerFailure('DB error')));
      return cubit;
    },
    act: (cubit) => cubit.loadEmployeeRecords('EMP001'),
    expect: () => [
      const EmployeeDetailLoading(),
      const EmployeeDetailError(ServerFailure('DB error')),
    ],
  );
}
