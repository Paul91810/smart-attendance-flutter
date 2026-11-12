import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import 'qr_validation_rule.dart';

class CheckOutWithoutCheckInRule extends QrValidationRule {
  const CheckOutWithoutCheckInRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    if (context.attendanceType != AttendanceType.checkOut) {
      return const Result.success(null);
    }

    final scanDay = context.scanTimestamp;
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

    if (todayRecords.isEmpty || todayRecords.last.type != AttendanceType.checkIn) {
      return const Result.failure(
        QrValidationFailure(
          'Cannot mark check-out without checking in first for today.',
          code: 'NO_CHECK_IN',
        ),
      );
    }

    return const Result.success(null);
  }
}
