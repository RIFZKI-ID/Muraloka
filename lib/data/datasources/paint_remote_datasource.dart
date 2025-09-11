import 'package:muraloka/data/models/paint_detail_response.dart';

abstract class PaintRemoteDatasource {
  Future<PaintDetailResponse> getPopularPaint();
}

class PaintRemoteDatasourceImpl implements PaintRemoteDatasource {
  //TODO: refactor to use Dio package(can find at di.dart)
  // static const API_KEY = ' ';
  // static const BASE_URL = 'https://';


  @override
  Future<PaintDetailResponse> getPopularPaint() {
    // TODO: implement getMovieDetail
    throw UnimplementedError();
  }
}
