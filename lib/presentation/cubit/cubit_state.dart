//===this file for state cubit===
part of 'cubit_cubit.dart';

abstract class CubitState extends Equatable {
  const CubitState();

  @override
  List<Object> get props => [];
}

class CubitInitial extends CubitState {}

class CubitLoading extends CubitState {}

class CubitLoaded extends CubitState {}

class CubitFailure extends CubitState {}
