import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/remote/order_datasource.dart';
import '../../../domain/entities/order.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderDataSource _ds;

  OrdersBloc(this._ds) : super(OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderStatusUpdateRequested>(_onUpdateStatus);
  }

  Future<void> _onLoad(OrdersLoadRequested e, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    try {
      final orders = await _ds.getOrders(status: e.status);
      emit(OrdersLoaded(orders: orders, statusFilter: e.status));
    } catch (err) {
      emit(OrdersFailure(err.toString()));
    }
  }

  Future<void> _onUpdateStatus(OrderStatusUpdateRequested e, Emitter<OrdersState> emit) async {
    try {
      await _ds.updateStatus(e.id, e.status);
      if (state is OrdersLoaded) {
        final s = state as OrdersLoaded;
        final updated = s.orders.map((o) {
          if (o.id == e.id) return o.copyWith(status: e.status);
          return o;
        }).toList();
        emit(s.copyWith(orders: updated));
      }
    } catch (err) {
      emit(OrdersFailure(err.toString()));
    }
  }
}
