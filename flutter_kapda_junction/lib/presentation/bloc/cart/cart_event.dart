part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartLoaded extends CartEvent {}

class CartItemAdded extends CartEvent {
  final Product product;
  final String? color;
  final String? size;
  const CartItemAdded({required this.product, this.color, this.size});
  @override
  List<Object?> get props => [product.id, color, size];
}

class CartItemRemoved extends CartEvent {
  final String productId;
  final String? color;
  final String? size;
  const CartItemRemoved({required this.productId, this.color, this.size});
  @override
  List<Object?> get props => [productId, color, size];
}

class CartItemQuantityUpdated extends CartEvent {
  final String productId;
  final String? color;
  final String? size;
  final int quantity;
  const CartItemQuantityUpdated({
    required this.productId,
    this.color,
    this.size,
    required this.quantity,
  });
  @override
  List<Object?> get props => [productId, color, size, quantity];
}

class CartCleared extends CartEvent {}
