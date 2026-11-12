import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_record.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<AttendanceRecord> records;
  final DateTime? dateFilter;

  const HistoryLoaded({
    required this.records,
    this.dateFilter,
  });

  @override
  List<Object?> get props => [records, dateFilter];
}

class HistoryEmpty extends HistoryState {
  final DateTime? dateFilter;

  const HistoryEmpty({this.dateFilter});

  @override
  List<Object?> get props => [dateFilter];
}

class HistoryFailure extends HistoryState {
  final String message;
  final String? code;

  const HistoryFailure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
