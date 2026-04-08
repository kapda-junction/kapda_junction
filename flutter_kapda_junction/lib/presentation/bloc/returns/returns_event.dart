part of 'returns_bloc.dart';

abstract class ReturnsEvent extends Equatable {
  const ReturnsEvent();
  @override
  List<Object?> get props => [];
}

class ReturnsLoadRequested extends ReturnsEvent {
  final String? orderId;
  const ReturnsLoadRequested({this.orderId});
  @override
  List<Object?> get props => [orderId];
}
