import 'package:bloc/bloc.dart';
import 'package:muraloka/domain/usecase/get_popular_paint_usecase.dart';
import 'package:muraloka/presentation/cubit/popular_paint_cubit/popular_paint_state.dart';

class PopularPaintCubit extends Cubit<PopularPaintState> {
  final GetPopularPaintUsecase getPopularPaintUsecase;

  PopularPaintCubit(this.getPopularPaintUsecase) : super(PopularPaintInitial());

  Future<void> fetchNowPlayingMovie() async {
    emit(PopularPaintLoading());

    final result = await getPopularPaintUsecase.execute();
    result.fold(
      (failure) {
        emit(PopularPaintError(failure.message));
      },
      (paintData) {
        emit(PopularPaintLoaded(paintData));
      },
    );
  }
}
