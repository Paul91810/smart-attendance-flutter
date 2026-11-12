import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import 'qr_validation_rule.dart';

class DuplicateAttendanceRule extends QrValidationRule {
  const DuplicateAttendanceRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    final scanDay = context.scanTimestamp;

    // Filter today's records for this specific employee, sorted chronologically
    final todayRecords = context.userAttendanceRecords
        .where((record) {
          if (record.employeeId != context.user.employeeId) return false;
          final recordDay = record.timestamp;
          return recordDay.year == scanDay.year &&
              recordDay.month == scanDay.month &&
              recordDay.day == scanDay.day;
        })
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (context.attendanceType == AttendanceType.checkIn) {
      // If already checked in and has not yet checked out, block duplicate check-in
      if (todayRecords.isNotEmpty && todayRecords.last.type == AttendanceType.checkIn) {
        return const Result.failure(
          QrValidationFailure(
            'You have already marked check-in. Please check out before checking in again.',
            code: 'DUPLICATE_ATTENDANCE',
          ),
        );
      }
    } else if (context.attendanceType == AttendanceType.checkOut) {
      // If already checked out, block duplicate check-out
      if (todayRecords.isNotEmpty && todayRecords.last.type == AttendanceType.checkOut) {
        return const Result.failure(
          QrValidationFailure(
            'You have already marked check-out. Please check in first.',
            code: 'DUPLICATE_ATTENDANCE',
          ),
        );
      }
    }

    return const Result.success(null);
  }
}

