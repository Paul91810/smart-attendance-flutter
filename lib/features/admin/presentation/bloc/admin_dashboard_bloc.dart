import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/get_attendance_records_usecase.dart';
import '../../domain/usecases/get_employees_usecase.dart';
import '../../domain/usecases/get_summary_usecase.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final GetSummaryUsecase getSummaryUsecase;
  final GetEmployeesUsecase getEmployeesUsecase;
  final GetAttendanceRecordsUsecase getAttendanceRecordsUsecase;

  DashboardSummary? _cachedSummary;
  List<Employee> _cachedEmployees = [];
  DateTime? _selectedDate;
  String? _selectedEmployeeId;

  AdminDashboardBloc({
    required this.getSummaryUsecase,
    required this.getEmployeesUsecase,
    required this.getAttendanceRecordsUsecase,
  }) : super(const AdminDashboardInitial()) {
    on<LoadAdminDashboard>(_onLoadDashboard);
    on<RefreshAdminDashboard>(_onRefreshDashboard);
    on<AdminDateFilterChanged>(_onDateFilterChanged);
    on<AdminEmployeeFilterChanged>(_onEmployeeFilterChanged);
    on<ClearAdminFilters>(_onClearFilters);
  }

  Future<void> _onLoadDashboard(
    LoadAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    await _loadFullData(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    await _loadFullData(emit);
  }

  Future<void> _onDateFilterChanged(
    AdminDateFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    _selectedDate = event.date;
    await _fetchFilteredRecords(emit);
  }

  Future<void> _onEmployeeFilterChanged(
    AdminEmployeeFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    _selectedEmployeeId = event.employeeId;
    await _fetchFilteredRecords(emit);
  }

  Future<void> _onClearFilters(
    ClearAdminFilters event,
    Emitter<AdminDashboardState> emit,
  ) async {
    _selectedDate = null;
    _selectedEmployeeId = null;
    await _fetchFilteredRecords(emit);
  }

  Future<void> _loadFullData(Emitter<AdminDashboardState> emit) async {
    final summaryResult = await getSummaryUsecase();
    if (summaryResult.isFailure) {
      final f = summaryResult.error;
      emit(AdminDashboardFailure(
        message: f?.message ?? 'Failed to load summary',
        code: f?.code,
      ));
      return;
    }

    final employeesResult = await getEmployeesUsecase();
    if (employeesResult.isFailure) {
      final f = employeesResult.error;
      emit(AdminDashboardFailure(
        message: f?.message ?? 'Failed to load employees',
        code: f?.code,
      ));
      return;
    }

    final recordsResult = await getAttendanceRecordsUsecase(
      date: _selectedDate,
      employeeId: _selectedEmployeeId,
    );
    if (recordsResult.isFailure) {
      final f = recordsResult.error;
      emit(AdminDashboardFailure(
        message: f?.message ?? 'Failed to load attendance records',
        code: f?.code,
      ));
      return;
    }

    _cachedSummary = summaryResult.data!;
    _cachedEmployees = employeesResult.data!;
    final records = recordsResult.data!;

    emit(AdminDashboardLoaded(
      summary: _cachedSummary!,
      employees: _cachedEmployees,
      records: records,
      selectedDate: _selectedDate,
      selectedEmployeeId: _selectedEmployeeId,
      isFiltering: false,
    ));
  }

  Future<void> _fetchFilteredRecords(Emitter<AdminDashboardState> emit) async {
    if (state is AdminDashboardLoaded) {
      emit((state as AdminDashboardLoaded).copyWith(isFiltering: true));
    }

    final recordsResult = await getAttendanceRecordsUsecase(
      date: _selectedDate,
      employeeId: _selectedEmployeeId,
    );

    if (recordsResult.isFailure) {
      final f = recordsResult.error;
      emit(AdminDashboardFailure(
        message: f?.message ?? 'Failed to filter records',
        code: f?.code,
      ));
      return;
    }

    final records = recordsResult.data!;

    if (_cachedSummary != null) {
      emit(AdminDashboardLoaded(
        summary: _cachedSummary!,
        employees: _cachedEmployees,
        records: records,
        selectedDate: _selectedDate,
        selectedEmployeeId: _selectedEmployeeId,
        isFiltering: false,
      ));
    } else {
      await _loadFullData(emit);
    }
  }
}
