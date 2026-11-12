import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/admin_repository.dart';

class GetSummaryUsecase {
  final AdminRepository repository;

  GetSummaryUsecase(this.repository);

  Future<Result<Failure, DashboardSummary>> call() async {
    return await repository.getDashboardSummary();
  }
}
