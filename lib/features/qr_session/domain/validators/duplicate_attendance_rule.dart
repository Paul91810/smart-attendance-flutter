import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'qr_validation_rule.dart';

class DuplicateAttendanceRule extends QrValidationRule {
  const DuplicateAttendanceRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    final scanDay = context.scanTimestamp;

    final hasDuplicate = context.userAttendanceRecords.any((record) {
      if (record.employeeId != context.user.employeeId) return false;
      if (record.type != context.attendanceType) return false;

      final recordDay = record.timestamp;
      return recordDay.year == scanDay.year &&
          recordDay.month == scanDay.month &&
          recordDay.day == scanDay.day;
    });

    if (hasDuplicate) {
      return Result.failure(
        QrValidationFailure(
          'You have already marked ${context.attendanceType.displayName.toLowerCase()} for today.',
          code: 'DUPLICATE_ATTENDANCE',
        ),
      );
    }

    return const Result.success(null);
  }
}

