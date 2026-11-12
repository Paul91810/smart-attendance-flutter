import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/usecases/get_my_attendance_history_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetMyAttendanceHistoryUsecase getMyAttendanceHistoryUsecase;
  List<AttendanceRecord> _allRecords = [];
  DateTime? _currentDateFilter;

  HistoryBloc({required this.getMyAttendanceHistoryUsecase})
      : super(const HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<RefreshHistory>(_onRefreshHistory);
    on<HistoryFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    await _fetchRecords(emit);
  }

  Future<void> _onRefreshHistory(
    RefreshHistory event,
    Emitter<HistoryState> emit,
  ) async {
    await _fetchRecords(emit);
  }

  void _onFilterChanged(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) {
    _currentDateFilter = event.date;
    _applyFilter(emit);
  }

  Future<void> _fetchRecords(Emitter<HistoryState> emit) async {
    final result = await getMyAttendanceHistoryUsecase();
    result.fold(
      (failure) {
        emit(HistoryFailure(
          message: failure.message,
          code: failure.code,
        ));
      },
      (records) {
        _allRecords = List<AttendanceRecord>.from(records);
        _applyFilter(emit);
      },
    );
  }

  void _applyFilter(Emitter<HistoryState> emit) {
    var filtered = _allRecords;
    if (_currentDateFilter != null) {
      filtered = _allRecords.where((r) {
        return r.timestamp.year == _currentDateFilter!.year &&
            r.timestamp.month == _currentDateFilter!.month &&
            r.timestamp.day == _currentDateFilter!.day;
      }).toList();
    }

    if (filtered.isEmpty) {
      emit(HistoryEmpty(dateFilter: _currentDateFilter));
    } else {
      emit(HistoryLoaded(
        records: filtered,
        dateFilter: _currentDateFilter,
      ));
    }
  }
}
