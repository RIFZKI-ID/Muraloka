import 'package:equatable/equatable.dart';
import 'package:muraloka/all_code/model/art_data.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

/// Status saat data berhasil dimuat
class HomeLoaded extends HomeState {
  final List<ArtItem> resumeArts;
  final List<ArtItem> popularArts;
  final List<ArtItem> popularAuthors;

  const HomeLoaded({
    required this.resumeArts,
    required this.popularArts,
    required this.popularAuthors,
  });

  @override
  List<Object> get props => [resumeArts, popularArts, popularAuthors];
}

class HomeFailure extends HomeState {
  final String message;

  const HomeFailure(this.message);

  @override
  List<Object> get props => [message];
}
