import 'package:equatable/equatable.dart';
import 'package:muraloka/domain/entities/paint.dart';

abstract class PopularPaintState extends Equatable {
  const PopularPaintState();

  @override
  List<Object> get props => [];
}

class PopularPaintInitial extends PopularPaintState {}

class PopularPaintLoading extends PopularPaintState {}

class PopularPaintLoaded extends PopularPaintState {
  final List<Paint> paint;

  const PopularPaintLoaded(this.paint);

  @override
  List<Object> get props => [paint];
}

class PopularPaintError extends PopularPaintState {
  final String message;

  const PopularPaintError(this.message);

  @override
  List<Object> get props => [message];
}
