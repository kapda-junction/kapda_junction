part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override List<Object?> get props => [];
}

class OrdersLoadRequested extends OrdersEvent {
  final String? status;
  const OrdersLoadRequested({this.status});
  @override List<Object?> get props => [status];
}

class OrderStatusUpdateRequested extends OrdersEvent {
  final String id;
  final String status;
  const OrderStatusUpdateRequested(this.id, this.status);
  @override List<Object?> get props => [id, status];
}
