import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_record.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceScanning extends AttendanceState {
  final AttendanceType type;

  const AttendanceScanning({this.type = AttendanceType.checkIn});

  @override
  List<Object?> get props => [type];
}

class AttendanceProcessing extends AttendanceState {
  final AttendanceType type;

  const AttendanceProcessing({required this.type});

  @override
  List<Object?> get props => [type];
}

class AttendanceSuccess extends AttendanceState {
  final AttendanceRecord record;

  const AttendanceSuccess({required this.record});

  @override
  List<Object?> get props => [record];
}

class AttendanceFailureState extends AttendanceState {
  final String code;
  final String message;
  final AttendanceType type;

  const AttendanceFailureState({
    required this.code,
    required this.message,
    this.type = AttendanceType.checkIn,
  });

  @override
  List<Object?> get props => [code, message, type];
}

