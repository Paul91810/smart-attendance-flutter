import '../../../attendance/domain/entities/attendance_record.dart';
import '../../domain/entities/admin_attendance_record.dart';

class AdminAttendanceRecordModel extends AdminAttendanceRecord {
  const AdminAttendanceRecordModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.sessionId,
    required super.synced,
  });

  factory AdminAttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecordModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      type: AttendanceType.fromString(json['type'] as String? ?? 'CHECK_IN'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      sessionId: json['sessionId'] as String? ?? '',
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type.toTypeString(),
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sessionId': sessionId,
      'synced': synced,
    };
  }
}
