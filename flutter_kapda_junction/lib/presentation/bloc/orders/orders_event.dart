part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class OrdersLoadRequested extends OrdersEvent {}

class OrderDetailRequested extends OrdersEvent {
  final String id;
  const OrderDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class OrderPaymentInitiated extends OrdersEvent {
  final Map<String, dynamic> body;
  const OrderPaymentInitiated(this.body);
  @override
  List<Object?> get props => [body];
}
