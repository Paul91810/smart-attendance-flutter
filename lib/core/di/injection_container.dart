import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../database/database_helper.dart';
import '../network/app_config.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../theme/theme_cubit.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

/// Centralized Dependency Injection registry using GetIt.
Future<void> initDependencies() async {
  // ===================== Core =====================
  sl.registerLazySingleton<AppConfig>(() => const AppConfig());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      getToken: () => sl<AuthLocalDataSource>().getToken(),
      onUnauthorized: () => sl<AuthLocalDataSource>().clear(),
    ),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      appConfig: sl(),
      authInterceptor: sl(),
    ),
  );

  // Theme
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());

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
}
