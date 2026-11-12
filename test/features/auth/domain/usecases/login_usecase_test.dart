import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/auth/domain/entities/user.dart';
import 'package:smart_attendance/features/auth/domain/entities/user_role.dart';
import 'package:smart_attendance/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUsecase(mockRepository);
  });

  const testUser = User(
    id: 'usr_emp_001',
    employeeId: 'EMP001',
    name: 'Alice Johnson',
    email: 'alice@smartattendance.com',
    role: UserRole.employee,
  );

  test('validates empty identifier and returns ValidationFailure', () async {
    final result = await usecase(
      const LoginParams(identifier: '', password: 'password123'),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, isA<ValidationFailure>());
    verifyZeroInteractions(mockRepository);
  });

  test('validates empty password and returns ValidationFailure', () async {
    final result = await usecase(
      const LoginParams(identifier: 'EMP001', password: ''),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, isA<ValidationFailure>());
    verifyZeroInteractions(mockRepository);
  });

  test('calls repository.login and returns User on valid params', () async {
    when(
      () => mockRepository.login(
        identifier: 'EMP001',
        password: 'password123',
      ),
    ).thenAnswer((_) async => const Result.success(testUser));

    final result = await usecase(
      const LoginParams(identifier: 'EMP001', password: 'password123'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.data, testUser);
    verify(
      () => mockRepository.login(
        identifier: 'EMP001',
        password: 'password123',
      ),
    ).called(1);
  });
}
