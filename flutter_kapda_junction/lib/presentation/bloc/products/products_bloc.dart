import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _repo;

  ProductsBloc(this._repo) : super(ProductsInitial()) {
    on<ProductsLoadRequested>(_onLoad);
    on<ProductsSearchRequested>(_onSearch);
    on<ProductDetailRequested>(_onDetail);
  }

  Future<void> _onLoad(
      ProductsLoadRequested event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    final result = await _repo.getProducts(
      search: event.search,
      category: event.category,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      size: event.size,
      color: event.color,
      page: event.page,
    );
    result.fold(
      (f) => emit(ProductsFailure(f.message)),
      (products) => emit(ProductsLoaded(products: products, hasMore: products.length >= 20)),
    );
  }

  Future<void> _onSearch(
      ProductsSearchRequested event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    final result = event.isAi
        ? await _repo.aiSearch(event.query)
        : await _repo.getProducts(search: event.query);
    result.fold(
      (f) => emit(ProductsFailure(f.message)),
      (products) => emit(ProductsLoaded(products: products, hasMore: false)),
    );
  }

  Future<void> _onDetail(
      ProductDetailRequested event, Emitter<ProductsState> emit) async {
    emit(ProductDetailLoading());
    final result = await _repo.getProductById(event.id);
    result.fold(
      (f) => emit(ProductsFailure(f.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }
}
