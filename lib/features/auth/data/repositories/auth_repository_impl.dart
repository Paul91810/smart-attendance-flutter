import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<Failure, User>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        identifier: identifier,
        password: password,
      );

      // Persist session tokens and user profile
      await localDataSource.saveToken(response.token);
      await localDataSource.saveUser(response.user);

      return Result.success(response.user.toEntity());
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(ServerFailure('Unexpected error during login: $e'));
    }
  }

  @override
  Future<Result<Failure, void>> logout() async {
    try {
      await localDataSource.clear();
      // Notify backend if connected
      final isOnline = await networkInfo.isConnected;
      if (isOnline) {
        await remoteDataSource.logout();
      }
      return Result.success(null);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Logout failed: $e'));
    }
  }

  @override
  Future<Result<Failure, User?>> getCurrentUser() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null || token.isEmpty) {
        return Result.success(null);
      }

      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Result.success(cachedUser.toEntity());
      }

      // If token exists but user was not cached, try fetching from remote
      final isOnline = await networkInfo.isConnected;
      if (isOnline) {
        final remoteUser = await remoteDataSource.getCurrentUser();
        await localDataSource.saveUser(remoteUser);
        return Result.success(remoteUser.toEntity());
      }

      return Result.success(null);
    } on AuthException catch (e) {
      await localDataSource.clear();
      return Result.failure(AuthFailure(e.message, code: e.code));
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to load session: $e'));
    }
  }

  @override
  Future<Result<Failure, String?>> getAuthToken() async {
    try {
      final token = await localDataSource.getToken();
      return Result.success(token);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to read auth token: $e'));
    }
  }
}
