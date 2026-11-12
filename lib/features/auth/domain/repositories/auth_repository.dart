import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/user.dart';

/// Abstract contract for authentication operations. Pure Dart domain interface.
abstract class AuthRepository {
  /// Authenticates a user with email or employee ID and password.
  Future<Result<Failure, User>> login({
    required String identifier,
    required String password,
  });

  /// Logs out the currently authenticated user, clearing local session tokens.
  Future<Result<Failure, void>> logout();

  /// Retrieves the currently authenticated user, if session exists.
  Future<Result<Failure, User?>> getCurrentUser();

  /// Retrieves the stored authentication token if present.
  Future<Result<Failure, String?>> getAuthToken();
}
