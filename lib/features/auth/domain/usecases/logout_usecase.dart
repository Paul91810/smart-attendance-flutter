import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Single-purpose usecase to terminate the current session and clean stored tokens.
class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<Result<Failure, void>> call() {
    return repository.logout();
  }
}
