import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/qr_session.dart';

/// Context containing all details needed by QR validation rules to verify an attendance scan.
class QrValidationContext {
  final QrSession session;
  final User user;
  final AttendanceType attendanceType;
  final DateTime scanTimestamp;
  final double latitude;
  final double longitude;
  final String hmacSecret;
  final Set<String> usedNonces;
  final List<AttendanceRecord> userAttendanceRecords;

  const QrValidationContext({
    required this.session,
    required this.user,
    required this.attendanceType,
    required this.scanTimestamp,
    required this.latitude,
    required this.longitude,
    required this.hmacSecret,
    required this.usedNonces,
    required this.userAttendanceRecords,
  });
}

/// Abstract Single-Responsibility interface for a QR validation rule (SOLID: S & O).
abstract class QrValidationRule {
  const QrValidationRule();

  Future<Result<Failure, void>> validate(QrValidationContext context);
}

