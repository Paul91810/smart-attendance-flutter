import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/qr_session.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_remote_datasource.dart';

class QrRepositoryImpl implements QrRepository {
  final QrRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QrRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<Failure, QrSession>> generateSession() async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      return Result.failure(const NetworkFailure());
    }

    try {
      final model = await remoteDataSource.generateSession();
      return Result.success(model.toEntity());
    } on AuthFailure catch (e) {
      return Result.failure(e);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Result.failure(ServerFailure('Failed to generate QR session: $e'));
    }
  }
}

