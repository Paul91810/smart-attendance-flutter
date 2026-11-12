import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/qr_session.dart';

abstract class QrRepository {
  Future<Result<Failure, QrSession>> generateSession();
}

