import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/qr_session.dart';
import '../repositories/qr_repository.dart';

/// Single-purpose usecase to request a new dynamic QR session for admin display.
class GenerateQrSessionUsecase {
  final QrRepository repository;

  GenerateQrSessionUsecase(this.repository);

  Future<Result<Failure, QrSession>> call() {
    return repository.generateSession();
  }
}

