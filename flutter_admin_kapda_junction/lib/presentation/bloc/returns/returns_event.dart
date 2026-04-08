part of 'returns_bloc.dart';

abstract class AdminReturnsEvent extends Equatable {
  const AdminReturnsEvent();
  @override
  List<Object?> get props => [];
}

class AdminReturnsLoadRequested extends AdminReturnsEvent {}

class AdminReturnUpdateRequested extends AdminReturnsEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminReturnUpdateRequested(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}
