import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import 'qr_validation_rule.dart';

class CheckOutWithoutCheckInRule extends QrValidationRule {
  const CheckOutWithoutCheckInRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    // Only check-out actions require prior check-in
    if (context.attendanceType != AttendanceType.checkOut) {
      return const Result.success(null);
    }

    final scanDay = context.scanTimestamp;
    final hasPriorCheckIn = context.userAttendanceRecords.any((record) {
      if (record.employeeId != context.user.employeeId) return false;
      if (record.type != AttendanceType.checkIn) return false;

      final recordDay = record.timestamp;
      return recordDay.year == scanDay.year &&
          recordDay.month == scanDay.month &&
          recordDay.day == scanDay.day;
    });

    if (!hasPriorCheckIn) {
      return Result.failure(
        const QrValidationFailure(
          'Cannot mark check-out without checking in first for today.',
          code: 'NO_CHECK_IN',
        ),
      );
    }

    return const Result.success(null);
  }
}

