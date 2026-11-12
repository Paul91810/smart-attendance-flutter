import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/qr_session.dart';
import 'qr_validation_rule.dart';

/// Single-responsibility rule verifying the HMAC-SHA256 signature to prevent tampering.
class SignatureRule extends QrValidationRule {
  const SignatureRule();

  @override
  Future<Result<Failure, void>> validate(QrValidationContext context) async {
    final expectedSignature = QrSession.computeHmacSignature(
      sessionId: context.session.sessionId,
      issuedAt: context.session.issuedAt,
      expiresAt: context.session.expiresAt,
      nonce: context.session.nonce,
      secret: context.hmacSecret,
    );

    if (context.session.signature != expectedSignature) {
      return Result.failure(
        const QrValidationFailure(
          'Invalid QR signature. Tampered or counterfeit QR code detected.',
          code: 'INVALID_SIGNATURE',
        ),
      );
    }

    return const Result.success(null);
  }
}

