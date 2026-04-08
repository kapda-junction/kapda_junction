part of 'returns_bloc.dart';

abstract class ReturnsState extends Equatable {
  const ReturnsState();
  @override
  List<Object?> get props => [];
}

class ReturnsInitial extends ReturnsState {}

class ReturnsLoading extends ReturnsState {}

class ReturnsLoaded extends ReturnsState {
  final List<ReturnRequest> returns;
  final bool returnsEnabled;
  const ReturnsLoaded({required this.returns, required this.returnsEnabled});
  @override
  List<Object?> get props => [returns, returnsEnabled];
}

class ReturnsFailure extends ReturnsState {
  final String message;
  const ReturnsFailure(this.message);
  @override
  List<Object?> get props => [message];
}
