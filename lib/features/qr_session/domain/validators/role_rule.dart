import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'qr_validation_rule.dart';

/// Single-responsibility rule verifying role permissions (only employees may mark attendance; admins cannot).
class RoleRule extends QrValidationRule {
  const RoleRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    if (context.user.isAdmin) {
      return Result.failure(
        const AuthFailure(
          'Administrators cannot mark attendance. Only employee accounts are authorized.',
          code: 'FORBIDDEN',
        ),
      );
    }

    if (context.user.employeeId.isEmpty) {
      return Result.failure(
        const AuthFailure(
          'Authentication required to mark attendance.',
          code: 'UNAUTHORIZED',
        ),
      );
    }

    return const Result.success(null);
  }
}
