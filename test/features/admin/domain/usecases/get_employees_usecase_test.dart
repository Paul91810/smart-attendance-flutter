import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/admin/domain/entities/employee.dart';
import 'package:smart_attendance/features/admin/domain/repositories/admin_repository.dart';
import 'package:smart_attendance/features/admin/domain/usecases/get_employees_usecase.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockRepository;
  late GetEmployeesUsecase usecase;

  setUp(() {
    mockRepository = MockAdminRepository();
    usecase = GetEmployeesUsecase(mockRepository);
  });

  const testEmployees = [
    Employee(
      id: 'usr_emp_001',
      employeeId: 'EMP001',
      name: 'John Doe',
      email: 'john.doe@smartattendance.com',
      role: 'employee',
      department: 'Engineering',
    ),
    Employee(
      id: 'usr_emp_002',
      employeeId: 'EMP002',
      name: 'Jane Smith',
      email: 'jane.smith@smartattendance.com',
      role: 'employee',
      department: 'Operations',
    ),
  ];

  test('calls repository.getEmployees and returns list on success', () async {
    when(() => mockRepository.getEmployees())
        .thenAnswer((_) async => const Result.success(testEmployees));

    final result = await usecase();

    expect(result.isSuccess, isTrue);
    expect(result.data, equals(testEmployees));
    verify(() => mockRepository.getEmployees()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns AuthFailure when user is not authorized as admin', () async {
    const failure = AuthFailure('Administrator privilege required.', code: 'FORBIDDEN');
    when(() => mockRepository.getEmployees())
        .thenAnswer((_) async => const Result.failure(failure));

    final result = await usecase();

    expect(result.isFailure, isTrue);
    expect(result.error, equals(failure));
    verify(() => mockRepository.getEmployees()).called(1);
  });
}
