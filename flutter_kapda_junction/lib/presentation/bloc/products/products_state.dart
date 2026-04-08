part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}
class ProductDetailLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final bool hasMore;
  const ProductsLoaded({required this.products, this.hasMore = false});
  @override
  List<Object?> get props => [products, hasMore];
}

class ProductDetailLoaded extends ProductsState {
  final Product product;
  const ProductDetailLoaded(this.product);
  @override
  List<Object?> get props => [product];
}

class ProductsFailure extends ProductsState {
  final String message;
  const ProductsFailure(this.message);
  @override
  List<Object?> get props => [message];
}
