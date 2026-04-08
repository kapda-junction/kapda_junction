part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
  @override List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}
class ProductsSaving extends ProductsState {}
class ProductSaveSuccess extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final int total;
  final int pages;
  final int page;

  const ProductsLoaded({
    required this.products,
    required this.total,
    required this.pages,
    required this.page,
  });

  ProductsLoaded copyWith({List<Product>? products, int? total, int? pages, int? page}) =>
      ProductsLoaded(
        products: products ?? this.products,
        total: total ?? this.total,
        pages: pages ?? this.pages,
        page: page ?? this.page,
      );

  @override List<Object?> get props => [products, total, pages, page];
}

class ProductsFailure extends ProductsState {
  final String message;
  const ProductsFailure(this.message);
  @override List<Object?> get props => [message];
}
