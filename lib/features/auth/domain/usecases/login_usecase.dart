import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String identifier;
  final String password;

  const LoginParams({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<Result<Failure, User>> call(LoginParams params) {
    if (params.identifier.trim().isEmpty) {
      return Future.value(
        Result.failure(
          const ValidationFailure('Please enter your email or employee ID'),
        ),
      );
    }
    if (params.password.isEmpty) {
      return Future.value(
        Result.failure(
          const ValidationFailure('Please enter your password'),
        ),
      );
    }

    return repository.login(
      identifier: params.identifier.trim(),
      password: params.password,
    );
  }
}
