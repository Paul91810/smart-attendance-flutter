import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUsecase {
  final AuthRepository repository;

  GetCurrentUserUsecase(this.repository);

  Future<Result<Failure, User?>> call() {
    return repository.getCurrentUser();
  }
}
