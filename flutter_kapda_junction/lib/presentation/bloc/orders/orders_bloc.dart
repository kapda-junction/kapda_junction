import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository _repo;

  OrdersBloc(this._repo) : super(OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderDetailRequested>(_onDetail);
    on<OrderPaymentInitiated>(_onPayment);
  }

  Future<void> _onLoad(
      OrdersLoadRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final result = await _repo.getOrders();
    result.fold(
      (f) => emit(OrdersFailure(f.message)),
      (orders) => emit(OrdersLoaded(orders)),
    );
  }

  Future<void> _onDetail(
      OrderDetailRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final result = await _repo.getOrderById(event.id);
    result.fold(
      (f) => emit(OrdersFailure(f.message)),
      (order) => emit(OrderDetailLoaded(order)),
    );
  }

  Future<void> _onPayment(
      OrderPaymentInitiated event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final result = await _repo.createPaymentOrder(event.body);
    result.fold(
      (f) => emit(OrdersFailure(f.message)),
      (data) => emit(OrderPaymentReady(data)),
    );
  }
}
