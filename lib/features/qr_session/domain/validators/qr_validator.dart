import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'checkout_without_checkin_rule.dart';
import 'duplicate_attendance_rule.dart';
import 'expiry_rule.dart';
import 'nonce_reuse_rule.dart';
import 'qr_validation_rule.dart';
import 'role_rule.dart';
import 'signature_rule.dart';

class QrValidator {
  final List<QrValidationRule> rules;

  const QrValidator({
    this.rules = const [
      SignatureRule(),
      ExpiryRule(),
      NonceReuseRule(),
      RoleRule(),
      DuplicateAttendanceRule(),
      CheckOutWithoutCheckInRule(),
    ],
  });

  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    for (final rule in rules) {
      final result = await rule.validate(context);
      if (result.isFailure) {
        return result;
      }
    }
    return const Result.success(null);
  }
}

