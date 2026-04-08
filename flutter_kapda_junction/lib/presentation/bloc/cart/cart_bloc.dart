import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final LocalStorage _storage;

  CartBloc(this._storage) : super(const CartState(items: [])) {
    on<CartLoaded>(_onLoaded);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartItemQuantityUpdated>(_onQuantityUpdated);
    on<CartCleared>(_onCleared);
  }

  Future<void> _onLoaded(CartLoaded event, Emitter<CartState> emit) async {
    // For now cart is managed in-memory; persistence can be added via local_storage
    emit(const CartState(items: []));
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere(
      (i) =>
          i.product.id == event.product.id &&
          i.selectedColor == event.color &&
          i.selectedSize == event.size,
    );
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(
        product: event.product,
        quantity: 1,
        selectedColor: event.color,
        selectedSize: event.size,
      ));
    }
    emit(CartState(items: items));
    _persist(items);
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final items = state.items
        .where((i) =>
            !(i.product.id == event.productId &&
                i.selectedColor == event.color &&
                i.selectedSize == event.size))
        .toList();
    emit(CartState(items: items));
    _persist(items);
  }

  void _onQuantityUpdated(
      CartItemQuantityUpdated event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere(
      (i) =>
          i.product.id == event.productId &&
          i.selectedColor == event.color &&
          i.selectedSize == event.size,
    );
    if (idx >= 0) {
      if (event.quantity <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = items[idx].copyWith(quantity: event.quantity);
      }
    }
    emit(CartState(items: items));
    _persist(items);
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
    _storage.clearCart();
  }

  void _persist(List<CartItem> items) {
    _storage.saveCartItems(items
        .map((i) => {
              'productId': i.product.id,
              'quantity': i.quantity,
              'color': i.selectedColor,
              'size': i.selectedSize,
            })
        .toList());
  }
}
