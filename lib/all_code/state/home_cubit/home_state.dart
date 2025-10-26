import 'package:equatable/equatable.dart';
// import 'package:muraloka/all_code/model/art_data.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/all_code/model/user.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

/// Status saat data berhasil dimuat
class HomeLoaded extends HomeState {
final List<Project> resumeProjects;
  final List<Project> popularProjects;
  final List<User> popularAuthors;

  const HomeLoaded({
    required this.resumeProjects,
    required this.popularProjects,
    required this.popularAuthors,
  });

  @override
  List<Object> get props => [resumeProjects, popularProjects, popularAuthors];
}

class HomeFailure extends HomeState {
  final String message;

  const HomeFailure(this.message);

  @override
  List<Object> get props => [message];
}
