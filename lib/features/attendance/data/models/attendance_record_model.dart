import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    super.id,
    required super.employeeId,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.sessionId,
    super.synced,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      employeeId: json['employeeId'] as String? ?? '',
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
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'type': type.toTypeString(),
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sessionId': sessionId,
      'synced': synced,
    };
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordModel(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as String? ?? '',
      type: AttendanceType.fromString(map['type'] as String? ?? 'CHECK_IN'),
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      sessionId: map['sessionId'] as String? ?? '',
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'type': type.toTypeString(),
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sessionId': sessionId,
      'synced': synced ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecord entity) {
    return AttendanceRecordModel(
      id: entity.id,
      employeeId: entity.employeeId,
      type: entity.type,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      sessionId: entity.sessionId,
      synced: entity.synced,
    );
  }
}

