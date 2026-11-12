import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/employee.dart';
import '../repositories/admin_repository.dart';

class GetEmployeesUsecase {
  final AdminRepository repository;

  GetEmployeesUsecase(this.repository);

  Future<Result<Failure, List<Employee>>> call() async {
    return await repository.getEmployees();
  }
}
