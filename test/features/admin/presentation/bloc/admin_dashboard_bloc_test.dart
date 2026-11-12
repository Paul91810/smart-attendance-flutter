import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/admin/domain/entities/admin_attendance_record.dart';
import 'package:smart_attendance/features/admin/domain/entities/dashboard_summary.dart';
import 'package:smart_attendance/features/admin/domain/entities/employee.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_attendance_records_usecase.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_employees_usecase.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_summary_usecase.dart';
import 'package:smart_attendance/features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:smart_attendance/features/admin/presentation/bloc/admin_dashboard_event.dart';
import 'package:smart_attendance/features/admin/presentation/bloc/admin_dashboard_state.dart';
import 'package:smart_attendance/features/attendance/domain/entities/attendance_record.dart';

class MockGetSummaryUsecase extends Mock implements GetSummaryUsecase {}
class MockGetEmployeesUsecase extends Mock implements GetEmployeesUsecase {}
class MockGetAttendanceRecordsUsecase extends Mock
    implements GetAttendanceRecordsUsecase {}

void main() {
  late MockGetSummaryUsecase mockSummaryUsecase;
  late MockGetEmployeesUsecase mockEmployeesUsecase;
  late MockGetAttendanceRecordsUsecase mockAttendanceRecordsUsecase;

  setUp(() {
    mockSummaryUsecase = MockGetSummaryUsecase();
    mockEmployeesUsecase = MockGetEmployeesUsecase();
    mockAttendanceRecordsUsecase = MockGetAttendanceRecordsUsecase();
  });

  const testSummary = DashboardSummary(
    totalEmployees: 5,
    presentToday: 2,
    checkedOutToday: 2,
  );

  const testEmployees = [
    Employee(
      id: 'usr_emp_001',
      employeeId: 'EMP001',
      name: 'John Doe',
      email: 'john@test.com',
      role: 'employee',
      department: 'IT',
    ),
  ];

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

  test('initial state is AdminDashboardInitial', () {
    final bloc = AdminDashboardBloc(
      getSummaryUsecase: mockSummaryUsecase,
      getEmployeesUsecase: mockEmployeesUsecase,
      getAttendanceRecordsUsecase: mockAttendanceRecordsUsecase,
    );
    expect(bloc.state, equals(const AdminDashboardInitial()));
    bloc.close();
  });

  blocTest<AdminDashboardBloc, AdminDashboardState>(
    'LoadAdminDashboard emits [AdminDashboardLoading, AdminDashboardLoaded] on success',
    build: () {
      when(() => mockSummaryUsecase())
          .thenAnswer((_) async => const Result.success(testSummary));
      when(() => mockEmployeesUsecase())
          .thenAnswer((_) async => const Result.success(testEmployees));
      when(() => mockAttendanceRecordsUsecase(date: null, employeeId: null))
          .thenAnswer((_) async => Result.success(testRecords));

      return AdminDashboardBloc(
        getSummaryUsecase: mockSummaryUsecase,
        getEmployeesUsecase: mockEmployeesUsecase,
        getAttendanceRecordsUsecase: mockAttendanceRecordsUsecase,
      );
    },
    act: (bloc) => bloc.add(const LoadAdminDashboard()),
    expect: () => [
      const AdminDashboardLoading(),
      AdminDashboardLoaded(
        summary: testSummary,
        employees: testEmployees,
        records: testRecords,
      ),
    ],
  );

  blocTest<AdminDashboardBloc, AdminDashboardState>(
    'LoadAdminDashboard emits [AdminDashboardLoading, AdminDashboardFailure] when summary fails',
    build: () {
      when(() => mockSummaryUsecase()).thenAnswer((_) async =>
          const Result.failure(ServerFailure('Summary error', code: 'SUMMARY_ERR')));

      return AdminDashboardBloc(
        getSummaryUsecase: mockSummaryUsecase,
        getEmployeesUsecase: mockEmployeesUsecase,
        getAttendanceRecordsUsecase: mockAttendanceRecordsUsecase,
      );
    },
    act: (bloc) => bloc.add(const LoadAdminDashboard()),
    expect: () => [
      const AdminDashboardLoading(),
      const AdminDashboardFailure(
        message: 'Summary error',
        code: 'SUMMARY_ERR',
      ),
    ],
  );

  blocTest<AdminDashboardBloc, AdminDashboardState>(
    'AdminDateFilterChanged and AdminEmployeeFilterChanged update records with isFiltering flag',
    build: () {
      when(() => mockSummaryUsecase())
          .thenAnswer((_) async => const Result.success(testSummary));
      when(() => mockEmployeesUsecase())
          .thenAnswer((_) async => const Result.success(testEmployees));
      when(() => mockAttendanceRecordsUsecase(date: null, employeeId: null))
          .thenAnswer((_) async => Result.success(testRecords));
      when(() => mockAttendanceRecordsUsecase(date: testDate, employeeId: null))
          .thenAnswer((_) async => Result.success(testRecords));

      return AdminDashboardBloc(
        getSummaryUsecase: mockSummaryUsecase,
        getEmployeesUsecase: mockEmployeesUsecase,
        getAttendanceRecordsUsecase: mockAttendanceRecordsUsecase,
      );
    },
    act: (bloc) async {
      bloc.add(const LoadAdminDashboard());
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(AdminDateFilterChanged(testDate));
    },
    expect: () => [
      const AdminDashboardLoading(),
      AdminDashboardLoaded(
        summary: testSummary,
        employees: testEmployees,
        records: testRecords,
      ),
      AdminDashboardLoaded(
        summary: testSummary,
        employees: testEmployees,
        records: testRecords,
        isFiltering: true,
      ),
      AdminDashboardLoaded(
        summary: testSummary,
        employees: testEmployees,
        records: testRecords,
        selectedDate: testDate,
        isFiltering: false,
      ),
    ],
  );
}
