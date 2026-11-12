import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/auth/domain/entities/user.dart';
import 'package:smart_attendance/features/auth/domain/entities/user_role.dart';
import 'package:smart_attendance/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:smart_attendance/features/auth/domain/usecases/login_usecase.dart';
import 'package:smart_attendance/features/auth/domain/usecases/logout_usecase.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUsecase extends Mock implements LoginUsecase {}
class MockLogoutUsecase extends Mock implements LogoutUsecase {}
class MockGetCurrentUserUsecase extends Mock implements GetCurrentUserUsecase {}

void main() {
  late MockLoginUsecase mockLoginUsecase;
  late MockLogoutUsecase mockLogoutUsecase;
  late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
  late AuthBloc authBloc;

  setUp(() {
    mockLoginUsecase = MockLoginUsecase();
    mockLogoutUsecase = MockLogoutUsecase();
    mockGetCurrentUserUsecase = MockGetCurrentUserUsecase();
    authBloc = AuthBloc(
      loginUsecase: mockLoginUsecase,
      logoutUsecase: mockLogoutUsecase,
      getCurrentUserUsecase: mockGetCurrentUserUsecase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const testUser = User(
    id: 'usr_admin_000',
    employeeId: 'EMP000',
    name: 'System Admin',
    email: 'admin@smartattendance.com',
    role: UserRole.admin,
  );

  test('initial state is AuthInitial', () {
    expect(authBloc.state, const AuthInitial());
  });

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when cached user exists',
      build: () {
        when(() => mockGetCurrentUserUsecase())
            .thenAnswer((_) async => const Result.success(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no cached user',
      build: () {
        when(() => mockGetCurrentUserUsecase())
            .thenAnswer((_) async => const Result.success(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });

  group('LoginSubmitted', () {
    const loginParams = LoginParams(
      identifier: 'admin@smartattendance.com',
      password: 'admin123',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful login',
      build: () {
        when(() => mockLoginUsecase(loginParams))
            .thenAnswer((_) async => const Result.success(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          identifier: 'admin@smartattendance.com',
          password: 'admin123',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] when login fails',
      build: () {
        when(() => mockLoginUsecase(loginParams))
            .thenAnswer((_) async => const Result.failure(
                  AuthFailure('Invalid email/employee ID or password'),
                ));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          identifier: 'admin@smartattendance.com',
          password: 'admin123',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailureState('Invalid email/employee ID or password'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on logout',
      build: () {
        when(() => mockLogoutUsecase())
            .thenAnswer((_) async => const Result.success(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });
}
