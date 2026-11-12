import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/admin_attendance_record.dart';

abstract class EmployeeDetailState extends Equatable {
  const EmployeeDetailState();

  @override
  List<Object?> get props => [];
}

class EmployeeDetailInitial extends EmployeeDetailState {
  const EmployeeDetailInitial();
}

class EmployeeDetailLoading extends EmployeeDetailState {
  const EmployeeDetailLoading();
}

class EmployeeDetailLoaded extends EmployeeDetailState {
  final List<AdminAttendanceRecord> records;

  const EmployeeDetailLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class EmployeeDetailError extends EmployeeDetailState {
  final Failure failure;

  const EmployeeDetailError(this.failure);

  @override
  List<Object?> get props => [failure];
}
