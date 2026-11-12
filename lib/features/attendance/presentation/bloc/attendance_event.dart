import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_record.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class ModeChanged extends AttendanceEvent {
  final AttendanceType type;

  const ModeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class ScanReceived extends AttendanceEvent {
  final String rawPayload;

  const ScanReceived(this.rawPayload);

  @override
  List<Object?> get props => [rawPayload];
}

class ResetAttendanceState extends AttendanceEvent {
  const ResetAttendanceState();
}

