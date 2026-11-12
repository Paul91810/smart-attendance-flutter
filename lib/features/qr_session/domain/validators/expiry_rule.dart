import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'qr_validation_rule.dart';

class ExpiryRule extends QrValidationRule {
  const ExpiryRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    if (context.session.isExpiredAt(context.scanTimestamp)) {
      return Result.failure(
        const QrValidationFailure(
          'QR code has expired. Please scan the updated QR code.',
          code: 'QR_EXPIRED',
        ),
      );
    }

    return const Result.success(null);
  }
}

