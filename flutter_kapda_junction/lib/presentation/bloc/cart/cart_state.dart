part of 'cart_bloc.dart';

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({required this.items});

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice => items.fold(0, (sum, i) => sum + i.totalPrice);

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items];
}
