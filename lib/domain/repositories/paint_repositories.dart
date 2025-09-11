import 'package:dartz/dartz.dart';
import 'package:muraloka/constant/failure.dart';
import 'package:muraloka/domain/entities/paint.dart';

abstract class PaintRepositories {
  Future<Either<Failure, List<Paint>>> getPopularPaint();
  Future<Either<Failure, List<Paint>>> getRecentPaint();
  Future<Either<Failure, Paint>> getDetailPaint();
}
