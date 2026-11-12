import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<Failure, User>> login({
    required String identifier,
    required String password,
  });

  Future<Result<Failure, void>> logout();

  Future<Result<Failure, User?>> getCurrentUser();

  Future<Result<Failure, String?>> getAuthToken();
}
