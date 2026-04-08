part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrdersState {
  final Order order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderPaymentReady extends OrdersState {
  final Map<String, dynamic> paymentData;
  const OrderPaymentReady(this.paymentData);
  @override
  List<Object?> get props => [paymentData];
}

class OrdersFailure extends OrdersState {
  final String message;
  const OrdersFailure(this.message);
  @override
  List<Object?> get props => [message];
}
