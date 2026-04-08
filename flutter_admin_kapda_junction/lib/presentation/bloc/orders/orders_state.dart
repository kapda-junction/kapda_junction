part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<AdminOrder> orders;
  final String? statusFilter;

  const OrdersLoaded({required this.orders, this.statusFilter});

  OrdersLoaded copyWith({List<AdminOrder>? orders, String? statusFilter}) =>
      OrdersLoaded(
        orders: orders ?? this.orders,
        statusFilter: statusFilter ?? this.statusFilter,
      );

  @override List<Object?> get props => [orders, statusFilter];
}

class OrdersFailure extends OrdersState {
  final String message;
  const OrdersFailure(this.message);
  @override List<Object?> get props => [message];
}
