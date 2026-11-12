import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../database/database_helper.dart';
import '../network/app_config.dart';
import '../network/auth_interceptor.dart';
import '../network/connectivity_cubit.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../services/location_service.dart';
import '../theme/theme_cubit.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

import '../../features/qr_session/data/datasources/qr_remote_datasource.dart';
import '../../features/qr_session/data/repositories/qr_repository_impl.dart';
import '../../features/qr_session/domain/repositories/qr_repository.dart';
import '../../features/qr_session/domain/usecases/generate_qr_session_usecase.dart';
import '../../features/qr_session/presentation/bloc/qr_session_bloc.dart';

import '../../features/attendance/data/datasources/attendance_local_datasource.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_my_attendance_history_usecase.dart';
import '../../features/attendance/domain/usecases/get_unsynced_records_usecase.dart';
import '../../features/attendance/domain/usecases/mark_attendance_usecase.dart';
import '../../features/attendance/domain/usecases/sync_attendance_usecase.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/bloc/history/history_bloc.dart';
import '../../features/attendance/presentation/bloc/sync/sync_cubit.dart';

import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/get_attendance_records_usecase.dart';
import '../../features/admin/domain/usecases/get_employees_usecase.dart';
import '../../features/admin/domain/usecases/get_summary_usecase.dart';
import '../../features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import '../../features/admin/presentation/bloc/employee_detail/employee_detail_cubit.dart';
import '../network/mock_attendance_store.dart';

final sl = GetIt.instance;

/// Centralized Dependency Injection registry using GetIt.
Future<void> initDependencies() async {
  // Ensure mock seed data is initialized for first launch
  MockAttendanceStore.seedInitialDataIfEmpty();

  // ===================== Core =====================
  sl.registerLazySingleton<AppConfig>(() => const AppConfig());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      getToken: () => sl<AuthLocalDataSource>().getToken(),
      onUnauthorized: () {
        sl<AuthLocalDataSource>().clear();
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const LogoutRequested());
        }
      },
    ),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      appConfig: sl(),
      authInterceptor: sl(),
    ),
  );

  // Theme & Connectivity
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());
  sl.registerFactory<ConnectivityCubit>(
    () => ConnectivityCubit(networkInfo: sl()),
  );

  // ===================== Auth Feature =====================
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<LoginUsecase>(() => LoginUsecase(sl()));
  sl.registerLazySingleton<LogoutUsecase>(() => LogoutUsecase(sl()));
  sl.registerLazySingleton<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl()),
  );

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUsecase: sl(),
      logoutUsecase: sl(),
      getCurrentUserUsecase: sl(),
    ),
  );

  // ===================== QR Session Feature =====================
  // Data Sources
  sl.registerLazySingleton<QrRemoteDataSource>(
    () => QrRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<QrRepository>(
    () => QrRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<GenerateQrSessionUsecase>(
    () => GenerateQrSessionUsecase(sl()),
  );

  // BLoC
  sl.registerFactory<QrSessionBloc>(
    () => QrSessionBloc(
      generateQrSessionUsecase: sl(),
    ),
  );

  // ===================== Attendance Feature =====================
  // Data Sources
  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(databaseHelper: sl()),
  );
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      authLocalDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<MarkAttendanceUsecase>(
    () => MarkAttendanceUsecase(sl()),
  );
  sl.registerLazySingleton<GetMyAttendanceHistoryUsecase>(
    () => GetMyAttendanceHistoryUsecase(sl()),
  );
  sl.registerLazySingleton<GetUnsyncedRecordsUsecase>(
    () => GetUnsyncedRecordsUsecase(sl()),
  );
  sl.registerLazySingleton<SyncAttendanceUsecase>(
    () => SyncAttendanceUsecase(sl()),
  );

  // BLoC
  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(
      locationService: sl(),
      markAttendanceUsecase: sl(),
    ),
  );
  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      getMyAttendanceHistoryUsecase: sl(),
    ),
  );
  sl.registerFactory<SyncCubit>(
    () => SyncCubit(
      syncAttendanceUsecase: sl(),
      getUnsyncedRecordsUsecase: sl(),
    ),
  );

  // ===================== Admin Feature =====================
  // Data Sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<GetEmployeesUsecase>(
    () => GetEmployeesUsecase(sl()),
  );
  sl.registerLazySingleton<GetAttendanceRecordsUsecase>(
    () => GetAttendanceRecordsUsecase(sl()),
  );
  sl.registerLazySingleton<GetSummaryUsecase>(
    () => GetSummaryUsecase(sl()),
  );

  // BLoC
  sl.registerFactory<AdminDashboardBloc>(
    () => AdminDashboardBloc(
      getSummaryUsecase: sl(),
      getEmployeesUsecase: sl(),
      getAttendanceRecordsUsecase: sl(),
    ),
  );
  sl.registerFactory<EmployeeDetailCubit>(
    () => EmployeeDetailCubit(
      getAttendanceRecordsUsecase: sl(),
    ),
  );
}
