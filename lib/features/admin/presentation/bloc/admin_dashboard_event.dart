import 'package:equatable/equatable.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminDashboardEvent {
  const LoadAdminDashboard();
}

class RefreshAdminDashboard extends AdminDashboardEvent {
  const RefreshAdminDashboard();
}

class AdminDateFilterChanged extends AdminDashboardEvent {
  final DateTime? date;

  const AdminDateFilterChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class AdminEmployeeFilterChanged extends AdminDashboardEvent {
  final String? employeeId;

  const AdminEmployeeFilterChanged(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class ClearAdminFilters extends AdminDashboardEvent {
  const ClearAdminFilters();
}
