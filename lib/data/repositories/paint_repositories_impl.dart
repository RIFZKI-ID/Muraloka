import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:muraloka/constant/exception.dart';
import 'package:muraloka/constant/failure.dart';
import 'package:muraloka/data/datasources/paint_local_datasource.dart';
import 'package:muraloka/data/datasources/paint_remote_datasource.dart';
import 'package:muraloka/domain/entities/paint.dart';
import 'package:muraloka/domain/repositories/paint_repositories.dart';

class PaintRepositoriesImpl implements PaintRepositories {
  final PaintLocalDatasource localDataSource;
  final PaintRemoteDatasource remoteDataSource;

  PaintRepositoriesImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Paint>>> getPopularPaint() async {
    // TODO: implement and refactor getPopularPaint
    // try {
    //   final result = await remoteDataSource.getPopularPaint();
    //   return Right(result.map((model) => model.toEntity()).toList());
    // } on ServerException {
    //   return Left(ServerFailure(''));
    // } on SocketException {
    //   return Left(ConnectionFailure('Failed to connect to the network'));
    // }
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Paint>>> getRecentPaint() async {
    // TODO: implement getRecentPaint
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Paint>> getDetailPaint() {
    // TODO: implement getDetailPaint
    throw UnimplementedError();
  }
}
