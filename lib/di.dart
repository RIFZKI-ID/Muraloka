//===this file for injection whole feature===
// don't put injection at main.dart

import 'package:get_it/get_it.dart';
import 'package:muraloka/data/datasources/db/paint_database_helper.dart';
import 'package:muraloka/data/datasources/paint_local_datasource.dart';
import 'package:muraloka/data/repositories/paint_repositories_impl.dart';
import 'package:muraloka/domain/repositories/paint_repositories.dart';
import 'package:muraloka/domain/usecase/get_popular_paint_usecase.dart';
import 'package:muraloka/presentation/cubit/cubit_cubit.dart';
import 'package:muraloka/presentation/cubit/popular_paint_cubit/popular_paint_cubit.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void init() {
  // cubit
  locator.registerFactory(() => PopularPaintCubit(locator()));

  // use case
  locator.registerLazySingleton(() => GetPopularPaintUsecase(locator()));

  // repository
  locator.registerLazySingleton<PaintRepositories>(
    () => PaintRepositoriesImpl(
      remoteDataSource: locator(),
      localDataSource: locator(),
    ),
  );

  // helper
  locator.registerLazySingleton<PaintDatabaseHelper>(
    () => PaintDatabaseHelper(),
  );

  // external
  locator.registerLazySingleton(() => Dio(BaseOptions(baseUrl: '',)));
}
