import 'package:dartz/dartz.dart';
import 'package:muraloka/constant/failure.dart';
import 'package:muraloka/domain/entities/paint.dart';
import 'package:muraloka/domain/repositories/paint_repositories.dart';

class GetPopularPaintUsecase {
  final PaintRepositories repository;

  GetPopularPaintUsecase(this.repository);

  Future<Either<Failure, List<Paint>>> execute() {
    return repository.getPopularPaint();
  }
}
