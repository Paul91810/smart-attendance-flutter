import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<Result<Failure, void>> call() {
    return repository.logout();
  }
}
