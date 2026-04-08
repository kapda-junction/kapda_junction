part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override List<Object?> get props => [];
}

class ProductsLoadRequested extends ProductsEvent {
  final int page;
  final String? search;
  final String? category;
  const ProductsLoadRequested({this.page = 1, this.search, this.category});
  @override List<Object?> get props => [page, search, category];
}

class ProductDeleteRequested extends ProductsEvent {
  final String id;
  const ProductDeleteRequested(this.id);
  @override List<Object?> get props => [id];
}

class ProductSaveRequested extends ProductsEvent {
  final String? id;
  final Map<String, dynamic> data;
  const ProductSaveRequested({this.id, required this.data});
  @override List<Object?> get props => [id, data];
}
