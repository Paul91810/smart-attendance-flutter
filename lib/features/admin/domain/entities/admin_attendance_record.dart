import 'package:equatable/equatable.dart';
import '../../../attendance/domain/entities/attendance_record.dart';

/// Pure Dart entity representing an enriched attendance record with employee metadata.
class AdminAttendanceRecord extends Equatable {
  final int id;
  final String employeeId;
  final String employeeName;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String sessionId;
  final bool synced;

  const AdminAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.sessionId,
    required this.synced,
  });

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employeeName,
        type,
        timestamp,
        latitude,
        longitude,
        sessionId,
        synced,
      ];
}
