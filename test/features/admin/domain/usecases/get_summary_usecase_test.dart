import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/admin/domain/entities/dashboard_summary.dart';
import 'package:smart_attendance/features/admin/domain/repositories/admin_repository.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_summary_usecase.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late GetSummaryUsecase usecase;

  setUp(() {
    mockRepository = MockAdminRepository();
    usecase = GetSummaryUsecase(mockRepository);
  });

  const testSummary = DashboardSummary(
    totalEmployees: 5,
    presentToday: 3,
    checkedOutToday: 1,
  );

  test('calls repository.getDashboardSummary and returns summary entity',
      () async {
    when(() => mockRepository.getDashboardSummary())
        .thenAnswer((_) async => const Result.success(testSummary));

    final result = await usecase();

    expect(result.isSuccess, isTrue);
    expect(result.data, equals(testSummary));
    expect(result.data?.absentToday, 1);
    verify(() => mockRepository.getDashboardSummary()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns Failure when repository fails', () async {
    const failure = NetworkFailure('No internet');
    when(() => mockRepository.getDashboardSummary())
        .thenAnswer((_) async => const Result.failure(failure));

    final result = await usecase();

    expect(result.isFailure, isTrue);
    expect(result.error, equals(failure));
  });
}
