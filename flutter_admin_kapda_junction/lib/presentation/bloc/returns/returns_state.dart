part of 'returns_bloc.dart';

abstract class AdminReturnsState extends Equatable {
  const AdminReturnsState();
  @override
  List<Object?> get props => [];
}

class AdminReturnsInitial extends AdminReturnsState {}

class AdminReturnsLoading extends AdminReturnsState {}

class AdminReturnsSaving extends AdminReturnsState {}

class AdminReturnSaveSuccess extends AdminReturnsState {}

class AdminReturnsLoaded extends AdminReturnsState {
  final List<AdminReturnRequest> returns;
  const AdminReturnsLoaded(this.returns);
  @override
  List<Object?> get props => [returns];
}

class AdminReturnsFailure extends AdminReturnsState {
  final String message;
  const AdminReturnsFailure(this.message);
  @override
  List<Object?> get props => [message];
}
