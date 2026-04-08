part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class ProductsLoadRequested extends ProductsEvent {
  final String? search;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? size;
  final String? color;
  final int page;
  const ProductsLoadRequested({
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.size,
    this.color,
    this.page = 1,
  });
  @override
  List<Object?> get props =>
      [search, category, minPrice, maxPrice, size, color, page];
}

class ProductsSearchRequested extends ProductsEvent {
  final String query;
  final bool isAi;
  const ProductsSearchRequested({required this.query, this.isAi = false});
  @override
  List<Object?> get props => [query, isAi];
}

class ProductDetailRequested extends ProductsEvent {
  final String id;
  const ProductDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}
