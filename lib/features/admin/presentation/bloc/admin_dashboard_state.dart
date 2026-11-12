import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_attendance_record.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/employee.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final DashboardSummary summary;
  final List<Employee> employees;
  final List<AdminAttendanceRecord> records;
  final DateTime? selectedDate;
  final String? selectedEmployeeId;
  final bool isFiltering;

  const AdminDashboardLoaded({
    required this.summary,
    required this.employees,
    required this.records,
    this.selectedDate,
    this.selectedEmployeeId,
    this.isFiltering = false,
  });

  AdminDashboardLoaded copyWith({
    DashboardSummary? summary,
    List<Employee>? employees,
    List<AdminAttendanceRecord>? records,
    DateTime? Function()? selectedDate,
    String? Function()? selectedEmployeeId,
    bool? isFiltering,
  }) {
    return AdminDashboardLoaded(
      summary: summary ?? this.summary,
      employees: employees ?? this.employees,
      records: records ?? this.records,
      selectedDate:
          selectedDate != null ? selectedDate() : this.selectedDate,
      selectedEmployeeId: selectedEmployeeId != null
          ? selectedEmployeeId()
          : this.selectedEmployeeId,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        employees,
        records,
        selectedDate,
        selectedEmployeeId,
        isFiltering,
      ];
}

class AdminDashboardFailure extends AdminDashboardState {
  final String message;
  final String? code;

  const AdminDashboardFailure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
