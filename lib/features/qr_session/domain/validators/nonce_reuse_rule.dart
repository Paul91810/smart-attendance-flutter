import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'qr_validation_rule.dart';

class NonceReuseRule extends QrValidationRule {
  const NonceReuseRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    if (context.usedNonces.contains(context.session.nonce)) {
      return Result.failure(
        const QrValidationFailure(
          'This QR code has already been scanned. Single-use dynamic code required.',
          code: 'QR_ALREADY_USED',
        ),
      );
    }

    return const Result.success(null);
  }
}

