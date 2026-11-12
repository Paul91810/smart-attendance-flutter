import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_attendance_records_usecase.dart';
import 'employee_detail_state.dart';

class EmployeeDetailCubit extends Cubit<EmployeeDetailState> {
  final GetAttendanceRecordsUsecase getAttendanceRecordsUsecase;

  EmployeeDetailCubit({required this.getAttendanceRecordsUsecase})
      : super(const EmployeeDetailInitial());

  Future<void> loadEmployeeRecords(String employeeId) async {
    emit(const EmployeeDetailLoading());
    final result = await getAttendanceRecordsUsecase(employeeId: employeeId);
    result.fold(
      (failure) => emit(EmployeeDetailError(failure)),
      (records) => emit(EmployeeDetailLoaded(records)),
    );
  }
}
