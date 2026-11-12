import 'package:equatable/equatable.dart';

/// Enum representing check-in or check-out attendance types.
enum AttendanceType {
  checkIn,
  checkOut;

  static AttendanceType fromString(String type) {
    final clean = type.trim().toUpperCase();
    if (clean == 'CHECK_OUT' || clean == 'CHECKOUT') {
      return AttendanceType.checkOut;
    }
    return AttendanceType.checkIn;
  }

  String toTypeString() {
    return this == AttendanceType.checkIn ? 'CHECK_IN' : 'CHECK_OUT';
  }

  String get displayName =>
      this == AttendanceType.checkIn ? 'Check In' : 'Check Out';
}

/// Pure domain entity representing an attendance check-in or check-out record.
class AttendanceRecord extends Equatable {
  final int? id;
  final String employeeId;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String sessionId;
  final bool synced;

  const AttendanceRecord({
    this.id,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.sessionId,
    this.synced = false,
  });

  AttendanceRecord copyWith({
    int? id,
    String? employeeId,
    AttendanceType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? sessionId,
    bool? synced,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sessionId: sessionId ?? this.sessionId,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        type,
        timestamp,
        latitude,
        longitude,
        sessionId,
        synced,
      ];

  @override
  String toString() =>
      'AttendanceRecord(id: $id, employeeId: $employeeId, type: ${type.toTypeString()}, time: $timestamp)';
}
