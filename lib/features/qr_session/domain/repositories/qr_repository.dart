import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/qr_session.dart';

/// Pure domain contract for generating and obtaining dynamic QR sessions.
abstract class QrRepository {
  /// Generates a new HMAC-signed, time-limited QR session from the backend.
  Future<Result<Failure, QrSession>> generateSession();
}
